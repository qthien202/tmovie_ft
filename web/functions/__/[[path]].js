// /__/auth/* and /__/firebase/*: Firebase Auth's handler pages served from our own domain (authDomain = this site),
// so Google sign-in redirects stay first-party in Safari and in the iOS home-screen app.
export async function onRequest({ request }) {
  const url = new URL(request.url);
  const target = 'https://tmovie-1db06.firebaseapp.com' + url.pathname + url.search;
  return fetch(new Request(target, request));
}
