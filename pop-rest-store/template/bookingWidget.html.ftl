<#-- Date-range rental booking widget, included by website.xml.
     Page authors embed <div data-growerp-booking></div> in any content page;
     this script renders an availability search and books directly against the
     anonymous PublicRooms / PublicBooking endpoints. Wording defaults to hotel
     rooms; a rental site overrides it per marker, e.g.
     <div data-growerp-booking data-noun="equipment" data-unit="day"
          data-title="Book equipment"></div>. -->
<style>
.growerp-booking{max-width:560px;margin:16px 0;padding:18px;border:1px solid #ddd;
  border-radius:12px;font-family:inherit;background:rgba(255,255,255,.9);color:#222}
.growerp-booking h3{margin:0 0 12px;font-size:18px}
.growerp-booking label{display:block;font-size:13px;margin:10px 0 4px}
.growerp-booking input{width:100%;box-sizing:border-box;border:1px solid #ccc;
  border-radius:6px;padding:8px;font-size:14px;font-family:inherit;
  background:#fff;color:#222}
.growerp-booking .growerp-bk-row{display:flex;gap:12px}
.growerp-booking .growerp-bk-row>div{flex:1 1 0}
.growerp-booking button{margin-top:14px;background:#2962ff;color:#fff;border:none;
  border-radius:6px;padding:10px 18px;font-size:14px;cursor:pointer}
.growerp-booking button:disabled{opacity:.6;cursor:default}
.growerp-booking .growerp-bk-room{display:flex;justify-content:space-between;
  align-items:center;gap:12px;border:1px solid #e0e0e0;border-radius:8px;
  padding:10px 12px;margin-top:10px}
.growerp-booking .growerp-bk-room.growerp-bk-full{opacity:.55}
.growerp-booking .growerp-bk-name{font-weight:bold}
.growerp-booking .growerp-bk-desc{font-size:12px;color:#666}
.growerp-booking .growerp-bk-price{white-space:nowrap;text-align:right}
.growerp-booking .growerp-bk-status{font-size:13px;min-height:18px;margin-top:8px}
.growerp-booking .growerp-bk-status.growerp-err{color:#c62828}
.growerp-booking .growerp-bk-status.growerp-ok{color:#2e7d32}
</style>
<script>
(function(){
  var origin  = window.location.origin;
  var roomsUrl   = origin + '/rest/s1/growerp/100/PublicRooms';
  var bookingUrl = origin + '/rest/s1/growerp/100/PublicBooking';
  var hostName = window.location.hostname;

  function el(tag, attrs, text){
    var e = document.createElement(tag);
    for (var k in (attrs||{})) e.setAttribute(k, attrs[k]);
    if (text) e.textContent = text;
    return e;
  }
  function isoDate(d){ return d.toISOString().substring(0,10); }

  function render(holder){
    // Wording is configurable per marker; defaults keep hotel pages unchanged.
    var noun  = holder.getAttribute('data-noun')  || 'room';
    var unit  = holder.getAttribute('data-unit')  || 'night';
    var title = holder.getAttribute('data-title') || ('Book a ' + noun);
    var unitCap = unit.charAt(0).toUpperCase() + unit.substring(1);

    var box = el('div', {'class':'growerp-booking'});
    box.appendChild(el('h3', {}, title));

    var tomorrow = new Date(Date.now() + 86400000);
    var row = el('div', {'class':'growerp-bk-row'});
    var fromWrap = el('div');
    fromWrap.appendChild(el('label', {'for':'growerp-bk-from'}, 'Arrival'));
    var fromInput = el('input', {id:'growerp-bk-from', type:'date'});
    fromInput.value = isoDate(tomorrow);
    fromWrap.appendChild(fromInput);
    var nightsWrap = el('div');
    nightsWrap.appendChild(el('label', {'for':'growerp-bk-nights'}, unitCap + 's'));
    var nightsInput = el('input', {id:'growerp-bk-nights', type:'number', min:'1'});
    nightsInput.value = '1';
    nightsWrap.appendChild(nightsInput);
    row.appendChild(fromWrap); row.appendChild(nightsWrap);
    box.appendChild(row);

    var searchBtn = el('button', {type:'button'}, 'Check availability');
    box.appendChild(searchBtn);
    var status = el('div', {'class':'growerp-bk-status'});
    box.appendChild(status);
    var results = el('div');
    box.appendChild(results);

    function setStatus(text, kind){
      status.className = 'growerp-bk-status' + (kind ? ' growerp-' + kind : '');
      status.textContent = text;
    }

    function guestForm(room){
      results.innerHTML = '';
      var form = el('form');
      form.appendChild(el('h3', {}, room.productName));
      form.appendChild(el('div', {'class':'growerp-bk-desc'},
        nightsInput.value + ' ' + unit + '(s) from ' + fromInput.value +
        ' — total ' + room.grandTotal));
      var fields = [
        {id:'growerp-bk-first', label:'First name', type:'text'},
        {id:'growerp-bk-last',  label:'Last name',  type:'text'},
        {id:'growerp-bk-email', label:'Email',      type:'email'}
      ];
      var inputs = {};
      fields.forEach(function(f){
        form.appendChild(el('label', {'for':f.id}, f.label + ' *'));
        var i = el('input', {id:f.id, type:f.type, required:'required'});
        inputs[f.id] = i;
        form.appendChild(i);
      });
      var bookBtn = el('button', {type:'submit'}, 'Confirm booking');
      form.appendChild(bookBtn);
      form.addEventListener('submit', function(ev){
        ev.preventDefault();
        bookBtn.disabled = true;
        setStatus('...', null);
        fetch(bookingUrl, {
          method:'POST',
          headers:{'Content-Type':'application/json','Accept':'application/json'},
          body: JSON.stringify({
            hostName: hostName,
            productId: room.productId,
            fromDate: fromInput.value,
            nights: parseInt(nightsInput.value, 10),
            firstName: inputs['growerp-bk-first'].value,
            lastName:  inputs['growerp-bk-last'].value,
            email:     inputs['growerp-bk-email'].value
          })
        }).then(function(r){ return r.json().then(function(j){ return {ok:r.ok, j:j}; }); })
          .then(function(res){
            if (res.ok) {
              results.innerHTML = '';
              setStatus(res.j.message || 'Your reservation is confirmed.', 'ok');
            } else {
              setStatus((res.j && res.j.errors) ? res.j.errors
                : 'Could not book, please try again', 'err');
              bookBtn.disabled = false;
            }
          }).catch(function(){
            setStatus('Could not book, please try again', 'err');
            bookBtn.disabled = false;
          });
      });
      results.appendChild(form);
    }

    function search(){
      searchBtn.disabled = true;
      results.innerHTML = '';
      setStatus('Searching...', null);
      var url = roomsUrl + '?hostName=' + encodeURIComponent(hostName) +
        '&fromDate=' + encodeURIComponent(fromInput.value) +
        '&nights=' + encodeURIComponent(nightsInput.value);
      fetch(url, {headers:{'Accept':'application/json'}})
        .then(function(r){ return r.json().then(function(j){ return {ok:r.ok, j:j}; }); })
        .then(function(res){
          searchBtn.disabled = false;
          if (!res.ok) {
            setStatus((res.j && res.j.errors) ? res.j.errors
              : 'Could not load availability', 'err');
            return;
          }
          var rooms = (res.j && res.j.rooms) || [];
          var free = rooms.filter(function(r){ return r.available > 0; });
          if (!free.length) {
            setStatus('No ' + noun + 's available for those dates', 'err');
            return;
          }
          setStatus('', null);
          free.forEach(function(room){
            var card = el('div', {'class':'growerp-bk-room'});
            var info = el('div');
            info.appendChild(el('div', {'class':'growerp-bk-name'}, room.productName));
            if (room.description)
              info.appendChild(el('div', {'class':'growerp-bk-desc'}, room.description));
            info.appendChild(el('div', {'class':'growerp-bk-desc'},
              room.available + ' available'));
            card.appendChild(info);
            var right = el('div', {'class':'growerp-bk-price'});
            right.appendChild(el('div', {}, room.grandTotal));
            var pick = el('button', {type:'button'}, 'Select');
            pick.addEventListener('click', function(){ guestForm(room); });
            right.appendChild(pick);
            card.appendChild(right);
            results.appendChild(card);
          });
        }).catch(function(){
          searchBtn.disabled = false;
          setStatus('Could not load availability', 'err');
        });
    }

    searchBtn.addEventListener('click', search);
    holder.appendChild(box);
  }

  function init(){
    document.querySelectorAll('[data-growerp-booking]').forEach(function(holder){
      if (holder.dataset.growerpBookingDone) return;
      holder.dataset.growerpBookingDone = '1';
      render(holder);
    });
  }
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', init);
  else init();
})();
</script>
