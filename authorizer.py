#!/usr/bin/env python3

import hashlib
import json


allow_policy = {
    "principalId": "user",
    "policyDocument": {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "execute-api:Invoke",
                "Effect": "Allow",
                "Resource": "arn:aws:execute-api:*:*:*",
            }
        ],
    },
}

deny_policy = {
    "principalId": "user",
    "policyDocument": {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "execute-api:Invoke",
                "Effect": "Deny",
                "Resource": "arn:aws:execute-api:*:*:*",
            }
        ],
    },
}

# echo -n "mmmm:aaa" | base64 | tr -d '\n'| sha256sum
hashed_tokens = ["d460b58da0ea02cb5bc247895904a4755401dbab6d45de599229a58f03ff6f61"]


def lambda_handler(event, context):
    """Handler to be called by AWS Lambda"""
    token = event.get("authorizationToken").split("Basic ")[1]

    # Hide token before logging
    event["authorizationToken"] = "***********"
    print(json.dumps(event))

    h_token = hashlib.sha256(token.encode()).hexdigest()
    if h_token not in hashed_tokens:
        return deny_policy
    return allow_policy


def test_lambda_handler():
    fake_event = """{"type": "TOKEN", "methodArn": "arn:aws:execute-api:eu-north-1:253037940910:c2nrqq4ig8/dev/GET/mattiastest123/dir1/dir2/packages", "authorizationToken": "Basic bW1tbTphYWE="}"""
    r = lambda_handler(json.loads(fake_event), None)
    print(r)


if __name__ == "__main__":
    test_lambda_handler()
