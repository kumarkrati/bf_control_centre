import * as EncodingMatrix from "./matrix.ts";

export function decompile(key: string): string {
  let ore = "";
  for (let i = 0; i < key.length; i++) {
    const char = key[i];
    if (char === "(" || char === ")") {
      ore += char;
      continue;
    }
    const decoded = EncodingMatrix.decode(char);
    if (decoded === null) {
      throw new Error("Unauthentic key.");
    } else {
      ore += decoded;
    }
  }

  const data = asMap(ore);
  const keyParts = Array(data.length).fill(0);
  for (const [secret, index] of data) {
    keyParts[index] = secret;
  }

  return keyParts.join("");
}

function asMap(ore: string): number[][] {
  const data: number[][] = [];
  let isIndexing = false;
  let secret = "";
  let index = "";

  for (let i = 0; i < ore.length; i++) {
    const char = ore[i];
    if (isIndexing && char !== ")") {
      index += char;
    } else if (char === "(") {
      isIndexing = true;
    } else if (char === ")") {
      isIndexing = false;
      data.push([parseInt(secret, 10), parseInt(index, 10)]);
      secret = "";
      index = "";
    } else {
      secret = char;
    }
  }

  return data;
}
