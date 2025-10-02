import { NestFactory } from '@nestjs/core';

import { MicroserviceOptions } from '@nestjs/microservices';
import { BullMqServer } from '@gitroom/nestjs-libraries/bull-mq-transport-new/strategy';

import { AppModule } from './app/app.module';
import { initializeSentry } from '@gitroom/nestjs-libraries/sentry/initialize.sentry';
initializeSentry('workers');

async function bootstrap() {
  process.env.IS_WORKER = 'true';

  // Create HTTP application for Cloud Run
  const app = await NestFactory.create(AppModule);
  
  // Also create microservice for BullMQ
  const microservice = app.connectMicroservice<MicroserviceOptions>({
    strategy: new BullMqServer(),
  });

  // Start both HTTP server and microservice
  await app.startAllMicroservices();
  
  const port = process.env.PORT || 3003;
  await app.listen(port);
  
  console.log(`Workers service is running on port ${port}`);
}

bootstrap();
