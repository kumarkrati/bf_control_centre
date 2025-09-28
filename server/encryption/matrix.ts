const encodingMatrix: Record<string, string[]> = {
  "1": ["A", "h", "m", "鬱"],
  "2": ["P", "Q", "g", "薔"],
  "3": ["#", "H", "S", "薇"],
  "4": ["-", "Z", "+", "齉"],
  "5": ["%", "÷", "/", "挨"],
  "6": ["n", "x", "y", "拶"],
  "7": ["L", "a", "t", "醤"],
  "8": ["_", "U", "V", "油"],
  "9": ["E", "G", "T", "躊"],
  "0": ["W", "v", "Y", "躇"],
};

export function encode(digit: string): string {
  const matrix = encodingMatrix[digit];
  if (!matrix) throw new Error(`Invalid digit: ${digit}`);
  const index = Math.floor(Math.random() * matrix.length);
  return matrix[index];
}

export function decode(coded: string): string | null {
  for (let i = 0; i < 10; i++) {
    const matrix = encodingMatrix[i.toString()];
    if (matrix && matrix.includes(coded)) {
      return i.toString();
    }
  }
  return null;
}
