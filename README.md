## Terraform w/Runway intro

Using runway, initialize a Terraform state management stack. This needs to be done within CloudFormation in order to work around a chick or the egg situation.

```
runway gen-sample cfn
```

Generates a sample CloudFormation stack for us that will perform this action. There is no `runway.yml` though, so you can create one with `runway init`/`runway new`

You can make use of a `Pipfile` and `Makefile` for this as we typically do for a runway project. These have been included here.

You may choose to rename your module to something more meaningful like `tf-state.cfn` and then deploy it.

Once deployed, grab the s3 bucket and dynamodb table names for the next step.

### TF sample

Next generate a sample terrfaform project within runway:

```
runway gen-sample tf
```

Update the `backend-us-east-1.tfvars` file to make use of the s3/ddb names that were created from the state module from the first step. Then deploy this stack to create a sqs queue.

Validate that you did not receive any errors before moving on.

### SNS topic

Create a new resource within `main.tf` a SNS topic deploy this.

### Topic subscriber

Add the SQS queue that was created as a subscriber to the SNS topic. See the documentation [sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) on how to do this and deploy.

### Test that it works

Within the AWS web console post a sample message to the topic and make sure that it ends up in the queue.

### Add another subscriber

What other subscribers could you add to this SNS topic?

Add the serverless framework [hello world](https://bitbucket.org/corpinfo/top-training-material/src/master/serverless-hello-world/serverless.yml) as a module to our runway project. Launch this before the terraform module.

Use the [terraform cf output data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudformation_export) to pass the ARN of the lambda function in as a SNS topic subscriber.

You'll need to allow for the SNS topic to invoke the lambda function.

Deploy, publish to topic, look to lambda invocation logs to ensure that the SNS topic was invoked.
