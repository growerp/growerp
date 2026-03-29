/* This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License. */
(function () {
  if ( typeof window.CustomEvent === "function" ) return false; //If not IE

  function CustomEvent ( event, params ) {
    params = params || { bubbles: false, cancelable: false, detail: undefined };
    var evt = document.createEvent( 'CustomEvent' );
    evt.initCustomEvent( event, params.bubbles, params.cancelable, params.detail );
    return evt;
   }

  CustomEvent.prototype = window.Event.prototype;

  window.CustomEvent = CustomEvent;
})();
var storeComps = {};

var moqui = {
    isString: function(obj) { return typeof obj === 'string'; },
    isBoolean: function(obj) { return typeof obj === 'boolean'; },
    isNumber: function(obj) { return typeof obj === 'number'; },
    isArray: function(obj) { return Object.prototype.toString.call(obj) === '[object Array]'; },
    isFunction: function(obj) { return Object.prototype.toString.call(obj) === '[object Function]'; },
    isPlainObject: function(obj) { return obj != null && typeof obj === 'object' && Object.prototype.toString.call(obj) === '[object Object]'; },

    NotFoundComponent: Vue.extend({ template: '<div><h4>Page not found!</h4></div>' }),
    EmptyComponent: Vue.extend({ template: '<div><div class="spinner"><div>Loading…</div></div></div>' }),

    LruMap: function(limit) {
        this.limit = limit; this.valueMap = {}; this.lruList = []; // end of list is least recently used
        this.put = function(key, value) {
            var lruList = this.lruList; var valueMap = this.valueMap;
            valueMap[key] = value; this._keyUsed(key);
            while (lruList.length > this.limit) { var rem = lruList.pop(); valueMap[rem] = null; }
        };
        this.get = function (key) {
            var value = this.valueMap[key];
            if (value) { this._keyUsed(key); }
            return value;
        };
        this.containsKey = function (key) { return !!this.valueMap[key]; };
        this._keyUsed = function(key) {
            var lruList = this.lruList;
            var lruIdx = -1;
            for (var i=0; i<lruList.length; i++) { if (lruList[i] === key) { lruIdx = i; break; }}
            if (lruIdx >= 0) { lruList.splice(lruIdx,1); }
            lruList.unshift(key);
        };
    }
};

/* ========== Notify and Error Handling ========== */

// TODO: adjust offset for final header height to stay just below the bottom of the header
moqui.notifyOpts = { delay:2000, offset:{x:20,y:120}, placement:{from:'top',align:'right'}, z_index:1100, type:'success',
    animate:{ enter:'animated fadeInDown', exit:'' } }; // no animate on exit: animated fadeOutUp
moqui.notifyOptsInfo = { delay:3000, offset:{x:20,y:120}, placement:{from:'top',align:'right'}, z_index:1100, type:'info',
    animate:{ enter:'animated fadeInDown', exit:'' } }; // no animate on exit: animated fadeOutUp
moqui.notifyOptsError = { delay:20000, offset:{x:20,y:120}, placement:{from:'top',align:'right'}, z_index:1100, type:'danger',
    animate:{ enter:'animated fadeInDown', exit:'' } }; // no animate on exit: animated fadeOutUp
moqui.notifyMessages = function(messages, errors, validationErrors) {
    var notified = false;
    if (messages) {
        if (moqui.isArray(messages)) {
            for (var mi=0; mi < messages.length; mi++) {
                var messageItem = messages[mi];
                if (moqui.isPlainObject(messageItem)) {
                    var msgType = messageItem.type; if (!msgType || !msgType.length) msgType = 'info';
                    $.notify({message:messageItem.message}, $.extend({}, moqui.notifyOptsInfo, { type:msgType }));
                } else {
                    $.notify({message:messageItem}, moqui.notifyOptsInfo);
                }
                notified = true;
            }
        } else {
            $.notify({message:messages}, moqui.notifyOptsInfo);
            notified = true;
        }
    }
    if (errors) {
        if (moqui.isArray(errors)) {
            for (var ei=0; ei < errors.length; ei++) {
                $.notify({message:errors[ei]}, moqui.notifyOptsError);
                notified = true;
            }
        } else {
            $.notify({message:errors}, moqui.notifyOptsError);
            notified = true;
        }
    }
    if (validationErrors) {
        if (moqui.isArray(validationErrors)) {
            for (var vei=0; vei < validationErrors.length; vei++) { moqui.notifyValidationError(validationErrors[vei]); notified = true; }
        } else {
            moqui.notifyValidationError(validationErrors); notified = true;
        }
    }
    return notified;
};
moqui.notifyValidationError = function(valError) {
    var message = valError;
    if (moqui.isPlainObject(valError)) {
        message = valError.message;
        if (valError.fieldPretty && valError.fieldPretty.length) message = message + " (for field " + valError.fieldPretty + ")";
    }
    $.notify({message:message}, moqui.notifyOptsError);
};
moqui.handleAjaxError = function(jqXHR, textStatus, errorThrown) {
    var resp = jqXHR.responseText;
    var respObj;
    try { respObj = JSON.parse(resp); } catch (e) { /* ignore error, don't always expect it to be JSON */ }
    console.warn('ajax ' + textStatus + ' (' + jqXHR.status + '), message ' + errorThrown /*+ '; response: ' + resp*/);
    // console.error('respObj: ' + JSON.stringify(respObj));

    if (jqXHR.status === 401 && window.storeApp) {
        window.storeApp.preLoginRoute = window.storeApp.$router.currentRoute;
        // handle login required but user not logged in, route to login
        window.storeApp.$router.push('/login');
    } else if (jqXHR.status === 0) {
        if (errorThrown.indexOf('abort') < 0) {
            var msg = 'Could not connect to server';
            $.notify({ message:msg }, moqui.notifyOptsError);
        }
    } else {
        var notified = false;
        if (respObj && moqui.isPlainObject(respObj)) { notified = moqui.notifyMessages(respObj.messageInfos, respObj.errors, respObj.validationErrors); }
        else if (resp && moqui.isString(resp) && resp.length) { notified = moqui.notifyMessages(resp); }
        if (!notified) {
            var errMsg = 'Error: ' + errorThrown + ' (' + textStatus + ')';
            $.notify({ message:errMsg }, moqui.notifyOptsError);
        }
    }
};

/* ========== Page Component Loading ========== */

moqui.componentCache = new moqui.LruMap(20);
moqui.handleLoadError = function (jqXHR, textStatus, errorThrown) {
    // NOTE: may want to do more or something different in the future, for now just do a notify
    moqui.handleAjaxError(jqXHR, textStatus, errorThrown);
};

Vue.component("route-placeholder", {
    props: { location: { type: String, required: true }, options: Object, properties: Object },
    data: function() { return { activeComponent: moqui.EmptyComponent }; },
    template: '<component :is="activeComponent" v-bind="properties"></component>',
    mounted: function() {
        var jsCompObj = this.options || {};
        // NOTE on cache: on initial load if there are multiple of the same component (like category-product) will load template multiple times, consider some sort of lock/wait
        var cachedComponent = moqui.componentCache.get(this.location);
        if (cachedComponent) {
            this.activeComponent = cachedComponent;
        } else {
            var vm = this;
            axios.get(this.location).then(function(res) {
                jsCompObj.template = res.data;
                var vueComp = Vue.extend(jsCompObj);
                vm.activeComponent = vueComp;
                moqui.componentCache.put(vm.location, vueComp);
            }, moqui.handleLoadError);
        }
    }
});
function getPlaceholderRoute(locationVar, name, props) {
    var component = {
        name:name,
        template: '<route-placeholder :location="$root.storeConfig.' + locationVar + '" :options="$root.storeComps.' + name + '" :properties="$props"></route-placeholder>'
    };
    if (props) { component.props = props; }
    return component;
}
