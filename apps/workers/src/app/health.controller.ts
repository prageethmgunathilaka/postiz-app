import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      service: 'workers',
      timestamp: new Date().toISOString(),
    };
  }

  @Get()
  getRoot() {
    return {
      message: 'Postiz Workers Service',
      status: 'running',
      timestamp: new Date().toISOString(),
    };
  }
}
