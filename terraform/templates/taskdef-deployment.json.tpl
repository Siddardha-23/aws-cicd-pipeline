{
  "family": "opsboard-deployment",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "${execution_role_arn}",
  "taskRoleArn": "${task_role_arn}",
  "containerDefinitions": [
    {
      "name": "deployment",
      "image": "<IMAGE1_NAME>",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5001,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "FLASK_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DB_HOST",
          "valueFrom": "/opsboard/deployment/db-host"
        },
        {
          "name": "DB_NAME",
          "valueFrom": "/opsboard/deployment/db-name"
        },
        {
          "name": "DB_USERNAME",
          "valueFrom": "/opsboard/deployment/db-username"
        },
        {
          "name": "DB_PASSWORD",
          "valueFrom": "/opsboard/deployment/db-password"
        },
        {
          "name": "DB_PORT",
          "valueFrom": "/opsboard/deployment/db-port"
        },
        {
          "name": "FLASK_SECRET_KEY",
          "valueFrom": "/opsboard/production/flask-secret-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/opsboard-deployment",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "deployment"
        }
      }
    }
  ]
}
