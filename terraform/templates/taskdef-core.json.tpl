{
  "family": "opsboard-core",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "${execution_role_arn}",
  "taskRoleArn": "${task_role_arn}",
  "containerDefinitions": [
    {
      "name": "core",
      "image": "<IMAGE1_NAME>",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "FLASK_ENV",
          "value": "production"
        },
        {
          "name": "DEPLOYMENT_SERVICE_URL",
          "value": "http://deployment-service.opsboard.local:5001"
        }
      ],
      "secrets": [
        {
          "name": "DB_HOST",
          "valueFrom": "/opsboard/core/db-host"
        },
        {
          "name": "DB_NAME",
          "valueFrom": "/opsboard/core/db-name"
        },
        {
          "name": "DB_USERNAME",
          "valueFrom": "/opsboard/core/db-username"
        },
        {
          "name": "DB_PASSWORD",
          "valueFrom": "/opsboard/core/db-password"
        },
        {
          "name": "DB_PORT",
          "valueFrom": "/opsboard/core/db-port"
        },
        {
          "name": "FLASK_SECRET_KEY",
          "valueFrom": "/opsboard/production/flask-secret-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/opsboard-core",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "core"
        }
      }
    }
  ]
}
