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

import groovy.json.JsonOutput
import org.moqui.Moqui
import org.moqui.context.ArtifactExecutionInfo
import org.moqui.context.ExecutionContextFactory
import org.spockframework.runtime.extension.IGlobalExtension
import org.spockframework.runtime.model.SpecInfo

/* Records which growerp.* services the Spock specs called, for
   backend/ci/service_coverage.py.

   The artifact stats of the fork only count REST calls, so the services are
   read from the artifact execution history of the spec's execution context,
   just before its cleanupSpec destroys that context. Services run async
   (registerOnCommit, fork) use their own context and are not counted.

   Writes build/service-hits.json: {"services": [name, ...]}.
   Registered in META-INF/services/org.spockframework.runtime.extension.IGlobalExtension.
 */
class ServiceCoverageExtension implements IGlobalExtension {
    static final Set<String> hits = Collections.synchronizedSet(new TreeSet<String>())

    @Override
    void visitSpec(SpecInfo spec) {
        spec.addCleanupSpecInterceptor { invocation ->
            ExecutionContextFactory ecf = Moqui.getExecutionContextFactory()
            if (ecf != null) collect(ecf.getExecutionContext().artifactExecution.history)
            invocation.proceed()
        }
    }

    static void collect(List<ArtifactExecutionInfo> infos) {
        for (ArtifactExecutionInfo aei in infos) {
            if (aei.typeEnum == ArtifactExecutionInfo.ArtifactType.AT_SERVICE && aei.name.startsWith('growerp.'))
                hits.add(aei.name)
            // getChildList() throws on a leaf (addAll(null)), read the field instead
            List<ArtifactExecutionInfo> children = aei.@childList
            if (children) collect(children)
        }
    }

    @Override
    void stop() {
        File out = new File(System.getProperty('growerp.serviceHitsFile', 'build/service-hits.json'))
        out.parentFile?.mkdirs()
        out.text = JsonOutput.prettyPrint(JsonOutput.toJson([services: new ArrayList<String>(hits)]))
    }
}
