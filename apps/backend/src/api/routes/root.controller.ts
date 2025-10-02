import { Controller, Get } from '@nestjs/common';
@Controller('/')
export class RootController {
  @Get('/')
  getRoot(): string {
    return 'App is running!';
  }

  @Get('/health')
  getHealth() {
    return {
      status: 'ok',
      service: 'backend',
      timestamp: new Date().toISOString(),
    };
  }
}
