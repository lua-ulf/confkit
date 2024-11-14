const char = 'あ';
const byteSize = new TextEncoder().encode(char).length;
console.log(byteSize);  // Outputs the number of bytes
