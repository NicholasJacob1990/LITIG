import { DailyEventObjectAppMessage } from '@daily-co/daily-js';
declare type SendAppMessage<Data = any> = (data: Data, to?: string) => void;
interface UseAppMessageArgs<Data> {
    /**
     * Optional event callback for [app-message](https://docs.daily.co/reference/daily-js/events/participant-events#app-message) event listener.
     * Receives this hook's sendAppMessage as an additional argument to avoid circular dependencies.
     */
    onAppMessage?(ev: DailyEventObjectAppMessage<Data>, sendAppMessage?: SendAppMessage<Data>): void;
}
/**
 * React hook to setup [app-message](https://docs.daily.co/reference/daily-js/events/participant-events#app-message) listeners and
 * to send messages via [sendAppMessage](https://docs.daily.co/reference/daily-js/instance-methods/send-app-message).
 */
export declare const useAppMessage: <Data = any>({ onAppMessage, }?: UseAppMessageArgs<Data>) => SendAppMessage<Data>;
export {};
