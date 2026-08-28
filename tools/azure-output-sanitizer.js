/*
Script:
azure-output-sanitizer.js

Purpose:
Sanitize Azure CLI and PowerShell output locally in the browser.

Project:
Azure Support Labs.

Learning focus:
JavaScript text processing, regular expressions, stable placeholder mapping,
and safe handling of Azure networking and access-related identifiers.

Lifecycle:
Permanent project component.
*/

const input = document.getElementById("input");
const output = document.getElementById("output");
const clearButton = document.getElementById("clearButton");
const copyButton = document.getElementById("copyButton");
const status = document.getElementById("status");

const inputEditorWrap = document.getElementById("inputEditorWrap");
const inputLineNumbers = document.getElementById("inputLineNumbers");
const outputLineNumbers = document.getElementById("outputLineNumbers");
const inputCount = document.getElementById("inputCount");
const outputCount = document.getElementById("outputCount");

const guidPattern =
  /\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b/g;

const ipv4Pattern =
  /\b(?:\d{1,3}\.){3}\d{1,3}\b/g;

const upnPattern =
  /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/g;

const macPattern =
  /\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b/g;

const sshPublicKeyPattern =
  /("keyData"\s*:\s*")((?:ssh-rsa|ssh-ed25519|ecdsa-sha2-[A-Za-z0-9@._+-]+|sk-ssh-ed25519@[A-Za-z0-9._-]+|sk-ecdsa-sha2-[A-Za-z0-9@._+-]+)\s+[A-Za-z0-9+/=]+(?:\s+[^"\r\n]+)?)(")/g;

function isValidIPv4(value) {
  const parts = value.split(".");

  if (parts.length !== 4) {
    return false;
  }

  return parts.every((part) => {
    if (!/^\d{1,3}$/.test(part)) {
      return false;
    }

    const number = Number(part);
    return number >= 0 && number <= 255;
  });
}

function isPrivateIPv4(value) {
  const parts = value.split(".").map(Number);
  const first = parts[0];
  const second = parts[1];

  return (
    first === 10 ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168)
  );
}

function isSpecialIPv4(value) {
  const parts = value.split(".").map(Number);
  const first = parts[0];
  const second = parts[1];
  const third = parts[2];

  return (
    first === 127 ||                                      // Loopback
    (first === 169 && second === 254) ||                 // Link-local
    (first === 100 && second >= 64 && second <= 127) || // CGNAT
    (first >= 224 && first <= 239) ||                    // Multicast
    first >= 240 ||                                      // Reserved
    (first === 192 && second === 0 && third === 2) ||    // TEST-NET-1
    (first === 198 && second === 51 && third === 100) || // TEST-NET-2
    (first === 203 && second === 0 && third === 113)     // TEST-NET-3
  );
}

function sanitizeText(text) {
  const state = {
    guidMap: new Map(),
    guidCounter: 0,

    privateIpMap: new Map(),
    privateIpCounter: 0,

    publicIpMap: new Map(),
    publicIpCounter: 0,

    specialIpMap: new Map(),
    specialIpCounter: 0,

    upnMap: new Map(),
    upnCounter: 0,

    macMap: new Map(),
    macCounter: 0,

    sshPublicKeyMap: new Map(),
    sshPublicKeyCounter: 0
  };

  let sanitized = text.replace(guidPattern, (value) => {
    if (!state.guidMap.has(value)) {
      state.guidCounter += 1;
      state.guidMap.set(value, `<GUID-${state.guidCounter}>`);
    }

    return state.guidMap.get(value);
  });

  sanitized = sanitized.replace(ipv4Pattern, (value) => {
    if (!isValidIPv4(value)) {
      return value;
    }

    if (value === "0.0.0.0") {
      return value;
    }

    if (isSpecialIPv4(value)) {
      if (!state.specialIpMap.has(value)) {
        state.specialIpCounter += 1;
        state.specialIpMap.set(
          value,
          `<SPECIAL-IP-${state.specialIpCounter}>`
        );
      }

      return state.specialIpMap.get(value);
    }

    if (isPrivateIPv4(value)) {
      if (!state.privateIpMap.has(value)) {
        state.privateIpCounter += 1;
        state.privateIpMap.set(
          value,
          `<PRIVATE-IP-${state.privateIpCounter}>`
        );
      }

      return state.privateIpMap.get(value);
    }

    if (!state.publicIpMap.has(value)) {
      state.publicIpCounter += 1;
      state.publicIpMap.set(
        value,
        `<PUBLIC-IP-${state.publicIpCounter}>`
      );
    }

    return state.publicIpMap.get(value);
  });

  sanitized = sanitized.replace(upnPattern, (value) => {
    if (!state.upnMap.has(value)) {
      state.upnCounter += 1;
      state.upnMap.set(
        value,
        `<UPN-${state.upnCounter}>`
      );
    }

    return state.upnMap.get(value);
  });

  sanitized = sanitized.replace(macPattern, (value) => {
    const normalized = value.toUpperCase().replaceAll("-", ":");

    if (!state.macMap.has(normalized)) {
      state.macCounter += 1;
      state.macMap.set(
        normalized,
        `<MAC-${state.macCounter}>`
      );
    }

    return state.macMap.get(normalized);
  });

  sanitized = sanitized.replace(
    sshPublicKeyPattern,
    (fullMatch, prefix, keyValue, suffix) => {
      if (!state.sshPublicKeyMap.has(keyValue)) {
        state.sshPublicKeyCounter += 1;
        state.sshPublicKeyMap.set(
          keyValue,
          `<SSH-PUBLIC-KEY-${state.sshPublicKeyCounter}>`
        );
      }

      return `${prefix}${state.sshPublicKeyMap.get(keyValue)}${suffix}`;
    }
  );

  return sanitized;
}

function countLines(text) {
  if (text === "") {
    return 1;
  }

  return text.split("\n").length;
}

function renderLineNumbers(container, text) {
  const total = countLines(text);
  const digits = [];

  for (let i = 1; i <= total; i += 1) {
    digits.push(i);
  }

  container.textContent = digits.join("\n");
}

function syncLineNumbersScroll(textarea, container) {
  container.scrollTop = textarea.scrollTop;
}

function refreshOutput() {
  const sanitized = sanitizeText(input.value);
  output.value = sanitized;

  inputCount.textContent = input.value.length;
  outputCount.textContent = sanitized.length;

  renderLineNumbers(inputLineNumbers, input.value);
  renderLineNumbers(outputLineNumbers, sanitized);
  syncLineNumbersScroll(input, inputLineNumbers);
  syncLineNumbersScroll(output, outputLineNumbers);

  status.textContent = input.value
    ? "Sanitized automatically."
    : "";
}

input.addEventListener("input", refreshOutput);
input.addEventListener("scroll", () => syncLineNumbersScroll(input, inputLineNumbers));
output.addEventListener("scroll", () => syncLineNumbersScroll(output, outputLineNumbers));

input.addEventListener("focus", () => {
  inputEditorWrap.classList.add("editor-active");
});

input.addEventListener("blur", () => {
  inputEditorWrap.classList.remove("editor-active");
});

clearButton.addEventListener("click", () => {
  input.value = "";
  output.value = "";
  status.textContent = "";
  inputCount.textContent = "0";
  outputCount.textContent = "0";
  renderLineNumbers(inputLineNumbers, "");
  renderLineNumbers(outputLineNumbers, "");
  input.focus();
});

copyButton.addEventListener("click", async () => {
  if (!output.value) {
    status.textContent = "Nothing to copy.";
    return;
  }

  try {
    await navigator.clipboard.writeText(output.value);
    status.textContent = "Sanitized output copied.";
  } catch {
    output.focus();
    output.select();
    document.execCommand("copy");
    status.textContent = "Sanitized output copied.";
  }
});

input.focus();
renderLineNumbers(inputLineNumbers, "");
renderLineNumbers(outputLineNumbers, "");
