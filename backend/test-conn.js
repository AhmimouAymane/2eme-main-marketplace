const net = require('net');
const client = new net.Socket();
client.connect(5432, '127.0.0.1', () => {
    console.log('Connected to 127.0.0.1:5432');
    process.exit(0);
});
client.on('error', (err) => {
    console.error('Connection failed:', err.message);
    process.exit(1);
});
setTimeout(() => {
    console.error('Connection timed out');
    process.exit(1);
}, 5000);
