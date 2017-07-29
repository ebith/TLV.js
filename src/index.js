import './index.css';

import Vue from 'vue';
import VueResource from 'vue-resource';
Vue.use(VueResource);

import Buefy from 'buefy';
import 'buefy/lib/buefy.css';
Vue.use(Buefy);

const synth = window.speechSynthesis;
const voices = synth.getVoices().filter((voice) => {
  return (voice.lang === 'ja-JP');
});

window.addEventListener('load', () => {
  const app = new Vue({
    el: '#app',
    data: {
      isOptionsModalActive: false,
      mute: false,
      volume: 0.5,
      skip: 0,
      log: [],
    },
    methods: {
      toggleMute: function (event) {
        if (event.target.checked) {
          this.mute = this.volume;
          this.volume = 0;
        } else {
          this.volume = this.mute;
          this.mute = false;
        }
      },
      getLog: function () {
        this.$http.get(`/recent.json?skip=${this.skip}&limit=20`).then((response) => {
          response.json().then((json) => {
            this.log = json.concat(this.log);
            this.skip += json.length;
          });
        });
      },
    },
    created: function () {
      this.$http.get('/recent.json').then((response) => {
        response.json().then((json) => {
          this.log = json;
          this.skip = json.length;
        });
      });
    },
  });

  const source = new EventSource('/stream');
  source.addEventListener('message', (msg) => {
    msg = JSON.parse(msg.data);

    if (!msg.is_notice) {
      const utter = new SpeechSynthesisUtterance(msg.log.replace(/(https?:\/\/\S+)/, 'URL省略'));
      utter.voice = voices[0];
      utter.volume = app.volume;
      synth.speak(utter);
    }

    app.log.push(msg);
  });
});
