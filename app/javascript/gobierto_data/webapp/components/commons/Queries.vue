<template>
  <div class="gobierto-data-summary-queries">
    <div class="gobierto-data-summary-queries-panel pure-g">
      <div class="pure-u-1-2 gobierto-data-summary-queries-panel-dropdown">
        <template v-if="isUserLogged">
          <Dropdown @is-content-visible="showPrivateQueries = !showPrivateQueries">
            <template v-slot:trigger>
              <h3 class="gobierto-data-summary-queries-panel-title">
                <Caret :rotate="!showPrivateQueries" />
                {{ labelYourQueries }} ({{ privateQueries.length }})
              </h3>
            </template>

            <div>
              <transition-group name="fade">
                <div
                  v-for="{ id, attributes: { sql, name, privacy_status }} in privateQueries"
                  :key="id"
                  class="gobierto-data-summary-queries-container"
                  @mouseover="showSQLCode(sql)"
                  @mouseleave="removeSQLCode()"
                >
                  <router-link
                    :to="`/datos/${$route.params.id}/q/${id}`"
                    class="gobierto-data-summary-queries-container-name"
                    @click.native="closeYourQueriesModal()"
                  >
                    {{ name }}
                  </router-link>

                  <div class="gobierto-data-summary-queries-container-icon">
                    <i
                      class="fas fa-trash-alt icons-your-queries"
                      style="color: var(--color-base);"
                      @click.stop="clickDeleteQueryHandler(id)"
                    />

                    <PrivateIcon
                      :is-closed="privacy_status === 'closed'"
                      class="icons-your-queries"
                    />
                  </div>
                </div>
              </transition-group>
            </div>
          </Dropdown>
        </template>
        <Dropdown @is-content-visible="showPublicQueries = !showPublicQueries">
          <template v-slot:trigger>
            <h3 class="gobierto-data-summary-queries-panel-title">
              <Caret :rotate="showPublicQueries" />

              {{ labelAll }}
              <template v-if="publicQueries.length">
                ({{ publicQueries.length }})
              </template>
            </h3>
          </template>
          <div v-if="publicQueries.length">
            <div
              v-for="{ id, attributes: { sql, name, author }} in publicQueries"
              :key="id"
              class="gobierto-data-summary-queries-container"
              @mouseover="showSQLCode(sql)"
              @mouseleave="removeSQLCode()"
            >
              <router-link
                :to="`/datos/${$route.params.id}/q/${id}`"
                class="gobierto-data-summary-queries-container-name"
                @click.native="closeYourQueriesModal()"
              >
                {{ name }}
              </router-link>

              <span style="display:block; padding-left:1em; font-size:0.875rem">
                <i
                  class="fas fa-user icons-your-queries"
                  style="color:var(--color-base);"
                />
                {{ author }}
              </span>
            </div>
          </div>
          <template v-else>
            <div class="gobierto-data-summary-queries-container">
              {{ labelQueryEmpty }}
            </div>
          </template>
        </Dropdown>
      </div>

      <div class="pure-u-1-2 border-color-queries">
        <p class="gobierto-data-summary-queries-sql-code">
          <textarea ref="querySnippet" />
        </p>
      </div>
    </div>
  </div>
</template>
<script>
import { Dropdown } from "lib/vue/components";
import Caret from "./Caret.vue";
import PrivateIcon from './PrivateIcon.vue';
import CodeMirror from "codemirror";
import "codemirror/mode/sql/sql.js";

export default {
  name: "Queries",
  components: {
    Caret,
    Dropdown,
    PrivateIcon
  },
  props: {
    privateQueries: {
      type: Array,
      default: () => []
    },
    publicQueries: {
      type: Array,
      default: () => []
    },
    isUserLogged: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      labelYourQueries: I18n.t("gobierto_data.projects.yourQueries") || "",
      labelQueryEmpty: I18n.t("gobierto_data.projects.queryEmpty") || "",
      labelFavs: I18n.t("gobierto_data.projects.favs") || "",
      labelAll: I18n.t("gobierto_data.projects.all") || "",
      labelDeleteQuery: I18n.t("gobierto_data.projects.deleteQuery") || "",
      sqlCode: null,
      showPrivateQueries: true,
      showPublicQueries: true,
    };
  },
  mounted() {
    const cmOption = {
      tabSize: 2,
      styleActiveLine: false,
      lineNumbers: false,
      styleSelectedText: false,
      line: true,
      foldGutter: true,
      mode: "text/x-sql",
      showCursorWhenSelecting: true,
      theme: "default",
      autoIndent: true
    };

    this.editor = CodeMirror.fromTextArea(this.$refs.querySnippet, cmOption);

    this.showPrivateQueries = !!this.privateQueries.length
    this.showPublicQueries = !!this.publicQueries.length
  },
  methods: {
    closeYourQueriesModal() {
      this.$root.$emit('runCurrentQuery')
      this.$emit('closeQueriesModal')
      this.$root.$emit('disabledStringSavedQuery')
    },
    clickDeleteQueryHandler(id) {
      const answerDelete = confirm(this.labelDeleteQuery);
      if (answerDelete) {
        this.$root.$emit('deleteSavedQuery', id)
      }
    },
    showSQLCode(code) {
      this.sqlCode = code
      this.editor.setValue(this.sqlCode);
    },
    removeSQLCode() {
      this.sqlCode = ''
      this.editor.setValue(this.sqlCode);
    }
  }
};
</script>
