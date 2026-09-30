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

/// Policy and incident dates are calendar dates: they are sent as noon UTC so
/// that converting to and from the time zone of the client or the server can
/// never move them to the previous or next day.
library;

DateTime? insuranceDateOnly(DateTime? date) =>
    date == null ? null : DateTime.utc(date.year, date.month, date.day, 12);
