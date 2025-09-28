function dirExistsSync(shopID: string) {
  try {
    Deno.lstatSync(`./${shopID}`);
    return true;
  } catch (_) {
    return false;
  }
}

export function prepareCacheStorage(shopID: string) {
  const shopCachePath = `_cache/${shopID}`;
  if (!dirExistsSync(shopCachePath)) {
    Deno.mkdirSync(shopCachePath, { recursive: true });
  }
}

export function prepareLogStorage() {
  const logDir = `.logs`;
  if (!dirExistsSync(logDir)) {
    Deno.mkdirSync(logDir);
  }
}