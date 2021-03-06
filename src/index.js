/* eslint-disable no-console */
import './index.css';

import Vue from 'vue';
import axios from 'axios';
import 'url-search-params-polyfill';

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
      info: {},
      location: document.location.origin,
      isOptionsModalActive: false,
      ignore: '',
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
        axios.get(`/recent.json?skip=${this.skip}&limit=20`).then((res) => {
          this.log = res.data.concat(this.log);
          this.skip += res.data.length;
        });
      },
    },
    created: function () {
      const params = new URLSearchParams(document.location.search.substring(1));
      const mute = params.get('mute') || false;
      if (mute === 'all') {
        this.mute = 0.5;
        this.volume = 0;
      } else if (mute !== false) {
        this.ignore = mute;
      }

      axios.get('/recent.json').then((res) => {
        this.log = res.data;
        this.skip = res.data.length;
      });
    },
  });

  const source = new EventSource('/stream');
  source.addEventListener('message', (msg) => {
    msg = JSON.parse(msg.data);

    if (msg.info) {
      app.info = msg.info;
      return;
    }

    if (!msg.is_notice && !app.ignore.includes(msg.nick)) {
      const utter = new SpeechSynthesisUtterance(msg.log.replace(/(https?:\/\/\S+)/, 'URL省略'));
      utter.voice = voices[0];
      utter.volume = app.volume;
      synth.speak(utter);
    }

    app.log.push(msg);
    if (document.documentElement.scrollHeight === window.scrollY + window.innerHeight) {
      Vue.nextTick(() => {
        window.scrollByLines(3);
      });
    }
  });

  setTimeout(() => {
    axios.post('/say', {
      notice: true,
      text: `${app.info.hostname}がTLV.js見てる`
    });
  }, 10000);
});
