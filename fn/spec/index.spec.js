const zlib = require("zlib");
const { run } = require("../src/");

const NAMESPACE = "namespace";
const BUCKET_NAME = "test-bucket";
const QUEUE_NAME = "test-queue";
const QUEUE_URL = `sqs/${QUEUE_NAME}`;

describe("", () => {
  let sqsClient, s3Client, lastS3Call, messages;

  beforeEach(() => {
    lastS3Call = null;
    messages = [{ ReceiptHandle: "abc", Body: JSON.stringify({ message: 1 }) }];

    sqsClient = {
      listQueues: jasmine.createSpy("listQueues").and.returnValue({
        promise: () => Promise.resolve({ QueueUrls: [QUEUE_URL] })
      }),

      receiveMessage: jasmine.createSpy("getMessages").and.returnValues(
        {
          promise: () => Promise.resolve({ Messages: messages })
        },
        {
          promise: () => Promise.resolve({})
        }
      ),

      deleteMessage: jasmine.createSpy("deleteMessage").and.returnValue({
        promise: () => Promise.resolve()
      })
    };

    s3Client = {
      putObject: jasmine.createSpy("putObject").and.callFake(details => {
        lastS3Call = details;
        return {
          promise: () => Promise.resolve()
        };
      })
    };
  });

  it("bails when queue not found", async () => {
    try {
      await run(BUCKET_NAME, "unknown-queue", NAMESPACE, sqsClient);
      fail("Should have thrown");
    } catch (e) {
      expect(e.message).toContain("Unable to find queue");
    }
    expect(sqsClient.listQueues).toHaveBeenCalledWith({
      QueueNamePrefix: "unknown-queue"
    });
  });

  it("bails when no messages are found", async () => {
    messages = [];
    await run(BUCKET_NAME, QUEUE_NAME, NAMESPACE, sqsClient);
    expect(sqsClient.listQueues).toHaveBeenCalledWith({
      QueueNamePrefix: QUEUE_NAME
    });
  });

  it("stores objects correctly", async () => {
    await run(BUCKET_NAME, QUEUE_NAME, NAMESPACE, sqsClient, s3Client);

    expect(sqsClient.listQueues).toHaveBeenCalledWith({
      QueueNamePrefix: QUEUE_NAME
    });

    expect(s3Client.putObject).toHaveBeenCalled();
    
    expect(sqsClient.deleteMessage).toHaveBeenCalledWith({
      QueueUrl: QUEUE_URL,
      ReceiptHandle: messages[0].ReceiptHandle
    });

    expect(lastS3Call.Bucket).toBe(BUCKET_NAME);
    expect(lastS3Call.Key.startsWith(NAMESPACE)).toBe(true);

    const buffer = lastS3Call.Body;
    const data = JSON.parse(zlib.gunzipSync(buffer));
    expect(data[0]).toEqual(JSON.parse(messages[0].Body));
  });
});
