// scripts/check_quota.js
// Quick check to see if quota has reset

const { checkQuotaStatus } = require('./upload_data.js');

console.log('\n🔍 QUOTA CHECKER');
console.log('=' .repeat(40));

checkQuotaStatus().then(() => {
  console.log('\n✅ Check complete');
}).catch(error => {
  console.error('❌ Check failed:', error.message);
});