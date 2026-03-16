// Firebase Cloud Messaging Service Worker
// This file is required for push notifications to work on web platform

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
// Replace these values with your Firebase config
const firebaseConfig = {
  apiKey: 'AIzaSyCnQSFvxZuRrb6W03fqn4Wvgdnl7mvpYRg',
  authDomain: 'helpnovaproject.firebaseapp.com',
  projectId: 'helpnovaproject',
  storageBucket: 'helpnovaproject.firebasestorage.app',
  messagingSenderId: '180526070893',
  appId: '1:180526070893:web:YOUR_WEB_APP_ID'
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Emergency Alert';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new emergency alert',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'emergency-alert',
    requireInteraction: true,
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // This looks to see if the current is already open and focuses if it is
  event.waitUntil(
    clients.matchAll({
      type: 'window'
    }).then((clientList) => {
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
