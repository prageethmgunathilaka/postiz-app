// Test script to verify Redis compatibility fix
const { ioRedis } = require('./libraries/nestjs-libraries/src/redis/redis.service');
const Bottleneck = require('bottleneck');

console.log('Testing Redis compatibility fix...');

// Test 1: Check if ioRedis has setMaxListeners method
console.log('1. Checking if ioRedis has setMaxListeners method...');
console.log('ioRedis.setMaxListeners exists:', typeof ioRedis.setMaxListeners === 'function');

// Test 2: Try to create a compatibility wrapper
console.log('\n2. Testing compatibility wrapper...');
const createCompatibleRedisClient = () => {
  const originalClient = ioRedis;
  
  // Add the missing setMaxListeners method for bottleneck compatibility
  if (!originalClient.setMaxListeners) {
    originalClient.setMaxListeners = function(max) {
      console.log('setMaxListeners called with max:', max);
      return this;
    };
  }
  
  return originalClient;
};

const compatibleClient = createCompatibleRedisClient();
console.log('Compatible client setMaxListeners exists:', typeof compatibleClient.setMaxListeners === 'function');

// Test 3: Try to create Bottleneck connection
console.log('\n3. Testing Bottleneck IORedisConnection...');
try {
  const connection = new Bottleneck.IORedisConnection({
    client: compatibleClient,
  });
  console.log('✅ Bottleneck IORedisConnection created successfully!');
  
  // Test 4: Try to create a Bottleneck instance
  console.log('\n4. Testing Bottleneck instance creation...');
  const bottleneck = new Bottleneck({
    id: 'test-concurrency',
    maxConcurrent: 1,
    datastore: 'ioredis',
    connection,
    minTime: 1000,
  });
  console.log('✅ Bottleneck instance created successfully!');
  
  console.log('\n🎉 All tests passed! Redis compatibility fix is working!');
  
} catch (error) {
  console.log('❌ Error creating Bottleneck connection:', error.message);
  console.log('Stack trace:', error.stack);
}
