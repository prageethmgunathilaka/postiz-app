import { NestFactory } from '@nestjs/core';

import { MicroserviceOptions } from '@nestjs/microservices';
import { BullMqServer } from '@gitroom/nestjs-libraries/bull-mq-transport-new/strategy';

import { AppModule } from './app/app.module';
import { initializeSentry } from '@gitroom/nestjs-libraries/sentry/initialize.sentry';
initializeSentry('workers');

async function bootstrap() {
  process.env.IS_WORKER = 'true';

  // Create microservice application for Cloud Run Jobs
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    strategy: new BullMqServer(),
  });

  // Start the microservice
  await app.listen();
  
  console.log('Workers job is running and listening for BullMQ messages');
}

bootstrap();
