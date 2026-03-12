/**
 * @format
 * Polyfill TextDecoder/TextEncoder cho Hermes (Android) — Stomp/WebSocket cần.
 */
import 'fast-text-encoding';

import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';

AppRegistry.registerComponent(appName, () => App);
