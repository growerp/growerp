/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.moqui.adk

import com.google.adk.agents.BaseAgent
import com.google.adk.agents.LlmAgent
import com.google.adk.tools.Annotations.Schema
import com.google.adk.tools.FunctionTool

/**
 * Example agent: reports the current time for a requested city.
 * Ported from the ADK Java quickstart sample (HelloTimeAgent).
 */
class HelloTimeAgent {

    static final BaseAgent ROOT_AGENT = initAgent()

    private static BaseAgent initAgent() {
        LlmAgent.builder()
            .name('hello-time-agent')
            .description('Tells the current time in a specified city')
            .instruction('''\
You are a helpful assistant that tells the current time in a city.
Use the 'getCurrentTime' tool for this purpose.
''')
            .model('gemini-3.5-flash-lite')
            .tools(FunctionTool.create(HelloTimeAgent.class, 'getCurrentTime'))
            .build()
    }

    /** Common city → IANA timezone lookup. Unknown cities fall back to UTC. */
    private static final Map<String, String> CITY_ZONES = [
        'bangkok'     : 'Asia/Bangkok',
        'bkk'         : 'Asia/Bangkok',
        'singapore'   : 'Asia/Singapore',
        'tokyo'       : 'Asia/Tokyo',
        'hong kong'   : 'Asia/Hong_Kong',
        'mumbai'      : 'Asia/Kolkata',
        'dubai'       : 'Asia/Dubai',
        'london'      : 'Europe/London',
        'paris'       : 'Europe/Paris',
        'berlin'      : 'Europe/Berlin',
        'amsterdam'   : 'Europe/Amsterdam',
        'new york'    : 'America/New_York',
        'los angeles' : 'America/Los_Angeles',
        'chicago'     : 'America/Chicago',
        'sao paulo'   : 'America/Sao_Paulo',
        'sydney'      : 'Australia/Sydney',
    ]

    @Schema(description = 'Get the current time for a given city')
    static Map<String, String> getCurrentTime(
            @Schema(name = 'city', description = 'Name of the city to get the time for') String city) {
        String key = city?.trim()?.toLowerCase()
        String zoneId = CITY_ZONES[key] ?: 'UTC'
        String time = java.time.ZonedDateTime.now(java.time.ZoneId.of(zoneId)).format(
            java.time.format.DateTimeFormatter.ofPattern('hh:mm a z'))
        return [city: city, currentTime: time]
    }
}
