/// <reference types="react" />
import { DailyEvent } from '@daily-co/daily-js';
interface EventContextValue {
    on(ev: DailyEvent, callback: Function, key: number): void;
    off(ev: DailyEvent, key: number): void;
}
export declare const DailyEventContext: import("react").Context<EventContextValue>;
export {};
