const fs = require("fs");
const zlib = require("zlib");
const AWS = require("aws-sdk");

const sqs = new AWS.SQS();
const s3 = new AWS.S3();

function lambdaHandler() {
  const { SQS_QUEUE_NAME: QUEUE_NAME, BUCKET_NAME, NAMESPACE } = process.env;

  if (QUEUE_NAME === undefined) throw new Error("QUEUE_NAME not defined");
  if (BUCKET_NAME === undefined) throw new Error("BUCKET_NAME not defined");
  if (NAMESPACE === undefined) throw new Error("NAMESPACE not defined");

  return run(BUCKET_NAME, QUEUE_NAME, NAMESPACE, sqs, s3);
}

async function run(bucketName, queueName, namespace, sqsClient, s3Client) {
  const queueUrl = await validateQueueExists(sqsClient, queueName);
  if (queueUrl === undefined)
    throw new Error(`Unable to find queue with name ${queueName}`);

  const messages = await getMessages(sqsClient, queueUrl);

  console.log(`Loaded ${messages.length} messages`);
  if (messages.length === 0)
    return console.log("Bailing out since there are no events to archive");

  const data = zlib.gzipSync(
    JSON.stringify(messages.map(m => JSON.parse(m.Body)))
  );

  const now = new Date();
  const key = `${namespace}/${now.getUTCFullYear()}/${now.getUTCMonth() +
    1}/${now.getUTCDate()}/${now.getUTCHours()}/${now.getUTCMinutes()}-${now.getUTCSeconds()}.json.gz`;
  console.log(`Storing data in ${bucketName} at ${key}`);

  await s3Client
    .putObject({
      Bucket: bucketName,
      Key: key,
      Body: data
    })
    .promise();

  console.log("Going to delete messages now");
  for (let i = 0; i < messages.length; i++) {
    await sqsClient
      .deleteMessage({
        QueueUrl: queueUrl,
        ReceiptHandle: messages[i].ReceiptHandle
      })
      .promise();
  }
  console.log("Done");
}

async function validateQueueExists(sqsClient, queueName) {
  const queues = (await sqsClient
    .listQueues({ QueueNamePrefix: queueName })
    .promise()).QueueUrls;
  return queues.find(q => q.endsWith(`/${queueName}`));
}

async function getMessages(sqsClient, queueUrl) {
  const messages = [];
  let loadedMessages = await getMoreMessages(sqsClient, queueUrl);
  while (loadedMessages.length > 0) {
    messages.push(...loadedMessages);
    loadedMessages = await getMoreMessages(sqsClient, queueUrl);
  }
  return messages;
}

async function getMoreMessages(sqsClient, queueUrl) {
  const sqsResponse = await sqsClient
    .receiveMessage({
      QueueUrl: queueUrl,
      MaxNumberOfMessages: 10,
      WaitTimeSeconds: 0
    })
    .promise();

  return sqsResponse.Messages || [];
}

module.exports = {
  lambdaHandler,
  run
};
