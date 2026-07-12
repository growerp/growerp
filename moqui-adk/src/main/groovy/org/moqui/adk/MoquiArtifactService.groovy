/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */
package org.moqui.adk

import com.google.adk.artifacts.BaseArtifactService
import com.google.adk.artifacts.ListArtifactsResponse
import com.google.common.collect.ImmutableList
import com.google.genai.types.Part
import io.reactivex.rxjava3.core.Completable
import io.reactivex.rxjava3.core.Maybe
import io.reactivex.rxjava3.core.Single
import org.moqui.context.ExecutionContextFactory
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import java.nio.charset.StandardCharsets
import java.sql.Timestamp

/**
 * ADK BaseArtifactService backed by the AdkArtifact Moqui entity, so large binaries
 * (PDFs, images) referenced by knowledge concepts stay out of the conversation context
 * and survive restarts; the agent loads them on demand (LoadArtifactsTool).
 *
 * Per ADK convention, filenames starting with "user:" are user-scoped: stored with an
 * empty session id so all of the user's sessions share them.
 */
class MoquiArtifactService implements BaseArtifactService {

    protected final static Logger logger = LoggerFactory.getLogger(MoquiArtifactService.class)
    private final static String USER_SCOPE_SESSION = '_user_'

    final ExecutionContextFactory ecf

    MoquiArtifactService(ExecutionContextFactory ecf) { this.ecf = ecf }

    private static String scopeSessionId(String sessionId, String filename) {
        return filename?.startsWith('user:') ? USER_SCOPE_SESSION : (sessionId ?: USER_SCOPE_SESSION)
    }

    @Override
    Single<Integer> saveArtifact(String appName, String userId, String sessionId, String filename, Part artifact) {
        Single.fromCallable {
            byte[] bytes
            String mimeType
            def blob = artifact?.inlineData()?.orElse(null)
            if (blob != null && blob.data().isPresent()) {
                bytes = blob.data().get()
                mimeType = blob.mimeType().orElse('application/octet-stream')
            } else if (artifact?.text()?.isPresent()) {
                bytes = artifact.text().get().getBytes(StandardCharsets.UTF_8)
                mimeType = 'text/plain'
            } else {
                throw new IllegalArgumentException("Artifact part for ${filename} has no inline data or text")
            }
            String scopedSession = scopeSessionId(sessionId, filename)

            withAuthz { ec ->
                def maxRow = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', scopedSession).condition('filename', filename)
                        .orderBy('-version').limit(1).list()
                int nextVersion = maxRow ? ((maxRow[0].version as int) + 1) : 0
                def av = ec.entity.makeValue('moqui.adk.AdkArtifact')
                av.setAll([appName: appName, userId: userId, sessionId: scopedSession,
                           filename: filename, version: nextVersion, mimeType: mimeType,
                           data: bytes, createdDate: new Timestamp(System.currentTimeMillis())])
                av.setSequencedIdPrimary()
                av.create()
                return nextVersion
            }
        }
    }

    @Override
    Maybe<Part> loadArtifact(String appName, String userId, String sessionId, String filename, Integer version) {
        Maybe.fromCallable {
            withAuthz { ec ->
                def find = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', scopeSessionId(sessionId, filename))
                        .condition('filename', filename)
                if (version != null) find.condition('version', version)
                def row = find.orderBy('-version').limit(1).list()
                if (!row) return null
                def dataObj = row[0].get('data')
                byte[] bytes = dataObj instanceof byte[] ? (byte[]) dataObj :
                        row[0].getSerialBlob('data')?.binaryStream?.bytes
                if (bytes == null) return null
                return Part.fromBytes(bytes, (row[0].mimeType ?: 'application/octet-stream') as String)
            }
        }
    }

    @Override
    Single<ListArtifactsResponse> listArtifactKeys(String appName, String userId, String sessionId) {
        Single.fromCallable {
            withAuthz { ec ->
                def sessionRows = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', sessionId ?: USER_SCOPE_SESSION)
                        .selectField('filename').distinct(true).list()
                def userRows = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', USER_SCOPE_SESSION)
                        .selectField('filename').distinct(true).list()
                def names = new TreeSet<String>()
                sessionRows.each { names.add(it.filename as String) }
                userRows.each { names.add(it.filename as String) }
                return ListArtifactsResponse.builder().filenames(new ArrayList<String>(names)).build()
            }
        }
    }

    @Override
    Completable deleteArtifact(String appName, String userId, String sessionId, String filename) {
        Completable.fromAction {
            withAuthz { ec ->
                def rows = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', scopeSessionId(sessionId, filename))
                        .condition('filename', filename).list()
                rows.each { it.delete() }
                return null
            }
        }
    }

    @Override
    Single<ImmutableList<Integer>> listVersions(String appName, String userId, String sessionId, String filename) {
        Single.fromCallable {
            withAuthz { ec ->
                def rows = ec.entity.find('moqui.adk.AdkArtifact')
                        .condition('appName', appName).condition('userId', userId)
                        .condition('sessionId', scopeSessionId(sessionId, filename))
                        .condition('filename', filename)
                        .selectField('version').orderBy('version').list()
                return ImmutableList.copyOf(rows.collect { it.version as Integer })
            }
        }
    }

    private <T> T withAuthz(Closure<T> work) {
        def ec = ecf.getExecutionContext()
        boolean wasDisabled = ec.artifactExecution.disableAuthz()
        try {
            return work(ec)
        } finally {
            if (!wasDisabled) ec.artifactExecution.enableAuthz()
        }
    }
}
