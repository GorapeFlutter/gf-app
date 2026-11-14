(() => {
  'use strict';

  const status = document.getElementById('status');
  const button = document.getElementById('continue');
  const fragment = new URLSearchParams(window.location.hash.slice(1));
  const challengeId = fragment.get('challenge_id');
  const apiOrigin = fragment.get('api_origin');
  const state = fragment.get('state');
  const returnValue = fragment.get('return_uri');
  window.history.replaceState(null, '', window.location.pathname + window.location.search);

  function decodeBase64Url(value) {
    const base64 = value.replace(/-/g, '+').replace(/_/g, '/')
      + '='.repeat((4 - value.length % 4) % 4);
    const binary = atob(base64);
    return Uint8Array.from(binary, (character) => character.charCodeAt(0)).buffer;
  }

  function encodeBase64Url(value) {
    const bytes = new Uint8Array(value);
    let binary = '';
    for (let offset = 0; offset < bytes.length; offset += 0x8000) {
      binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  }

  function convertCreationOptions(options) {
    options.challenge = decodeBase64Url(options.challenge);
    options.user.id = decodeBase64Url(options.user.id);
    for (const item of options.excludeCredentials || []) item.id = decodeBase64Url(item.id);
    return options;
  }

  function convertRequestOptions(options) {
    options.challenge = decodeBase64Url(options.challenge);
    for (const item of options.allowCredentials || []) item.id = decodeBase64Url(item.id);
    return options;
  }

  async function post(path, body) {
    const response = await fetch(`${apiOrigin}${path}`, {
      method: 'POST',
      credentials: 'omit',
      cache: 'no-store',
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: JSON.stringify(body),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.code || 'ceremony_rejected');
    return payload;
  }

  function validReturnUri() {
    if (!returnValue || !state) return null;
    const uri = new URL(returnValue);
    if (uri.protocol !== 'http:' || uri.hostname !== '127.0.0.1' ||
        uri.port !== '8402' ||
        uri.pathname !== '/passkey-result' ||
        uri.searchParams.get('state') !== state) return null;
    return uri;
  }

  function finish(result) {
    const uri = validReturnUri();
    if (!uri) {
      status.textContent = 'The desktop application callback is invalid.';
      return;
    }
    for (const [key, value] of Object.entries(result)) {
      if (value !== undefined && value !== null) uri.searchParams.set(key, String(value));
    }
    window.location.replace(uri.toString());
  }

  let preparedOptions;

  async function prepare() {
    if (!challengeId || !apiOrigin || !state || !validReturnUri()) {
      throw new Error('invalid_browser_ceremony_ticket');
    }
    preparedOptions = await post('/v1/passkeys/browser/options', {
      challenge_id: challengeId,
    });
    if (preparedOptions.ceremony === 'registration') {
      preparedOptions.public_key = convertCreationOptions(preparedOptions.public_key);
      status.textContent = 'Ready. Continue to create a Gorape passkey.';
    } else if (preparedOptions.ceremony === 'authentication') {
      preparedOptions.public_key = convertRequestOptions(preparedOptions.public_key);
      status.textContent = 'Ready. Continue to verify your Gorape passkey.';
    } else {
      throw new Error('unsupported_browser_ceremony');
    }
    button.disabled = false;
  }

  async function run() {
    button.disabled = true;
    if (!preparedOptions) throw new Error('ceremony_not_ready');
    const optionsResponse = preparedOptions;
    let credential;
    if (optionsResponse.ceremony === 'registration') {
      status.textContent = 'Create a Gorape passkey in your credential provider.';
      const creation = navigator.credentials.create({publicKey: optionsResponse.public_key});
      credential = await creation;
      if (!credential) throw new Error('credential_creation_cancelled');
      const response = credential.response;
      const verified = await post('/v1/passkeys/browser/registration/verify', {
        challenge_id: challengeId,
        credential: {
          id: credential.id,
          rawId: encodeBase64Url(credential.rawId),
          type: credential.type,
          authenticatorAttachment: credential.authenticatorAttachment,
          response: {
            clientDataJSON: encodeBase64Url(response.clientDataJSON),
            attestationObject: encodeBase64Url(response.attestationObject),
            transports: response.getTransports ? response.getTransports() : [],
          },
          clientExtensionResults: credential.getClientExtensionResults(),
        },
      });
      finish({
        status: 'verified',
        device_id: verified.device && verified.device.id,
      });
      return;
    }
    if (optionsResponse.ceremony !== 'authentication') {
      throw new Error('unsupported_browser_ceremony');
    }
    status.textContent = 'Verify possession of the Gorape passkey.';
    const assertion = navigator.credentials.get({publicKey: optionsResponse.public_key});
    credential = await assertion;
    if (!credential) throw new Error('credential_assertion_cancelled');
    const response = credential.response;
    await post('/v1/passkeys/browser/authentication/verify', {
      challenge_id: challengeId,
      credential: {
        id: credential.id,
        rawId: encodeBase64Url(credential.rawId),
        type: credential.type,
        authenticatorAttachment: credential.authenticatorAttachment,
        response: {
          clientDataJSON: encodeBase64Url(response.clientDataJSON),
          authenticatorData: encodeBase64Url(response.authenticatorData),
          signature: encodeBase64Url(response.signature),
          userHandle: response.userHandle ? encodeBase64Url(response.userHandle) : null,
        },
        clientExtensionResults: credential.getClientExtensionResults(),
      },
    });
    finish({status: 'verified'});
  }

  function fail(error) {
    status.textContent = 'Passkey verification failed. Return to the Gorape application.';
    finish({status: 'error', error: 'browser_ceremony_failed'});
  }

  button.addEventListener('click', () => run().catch(fail));
  prepare().catch(fail);
})();
