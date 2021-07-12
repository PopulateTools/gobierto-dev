// eslint-disable-next-line
import Turbolinks from 'turbolinks'
import { AUTOCOMPLETE_DEFAULTS } from 'lib/shared'
import 'devbridge-autocomplete'

document.addEventListener('DOMContentLoaded', function() {
  var $input = $('input#gobierto_search:visible');
  var $mobile_input = $('input#gobierto_search_mobile');

  function truncateOnWord(str, limit) {
    var trimmable = '\u0009\u000A\u000B\u000C\u000D\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u2028\u2029\u3000\uFEFF';
    var reg = new RegExp('(?=[' + trimmable + '])');
    var words = str.split(reg);
    var count = 0;
    return words.filter(function(word) {
      count += word.length;
      return count <= limit;
    }).join('');
  }

  function itemUpdatedAt(d){
    if (d['searchable_updated_at'] == null)
      return;

    return `${I18n.t("layouts.search.updated")}: ${I18n.l("date.formats.short", d['searchable_updated_at'])}`;
  }

  function itemDescription(d){
    var maxLength = 200;
    var description = (d['description'] || '');
    if (description === '' || description.length < maxLength)
      return description;
    return truncateOnWord(description, maxLength) + '...';
  }

  function itemType(d){
    let class_name = d['class_name'] || d['searchable_type']
    if (class_name === undefined)
      return;

    switch (class_name){
      case 'GobiertoPeople::Person':
        return I18n.t("layouts.search.person_item");
      case 'GobiertoPeople::PersonPost':
        return I18n.t("layouts.search.person_post_item");
      case 'GobiertoCalendars::Event':
        return I18n.t("layouts.search.event_item");
      case 'GobiertoPeople::PersonStatement':
        return I18n.t("layouts.search.person_statement_item");
      case 'GobiertoCms::Page':
        return I18n.t("layouts.search.page_item");
      case 'GobiertoBudgets::BudgetLine':
        if (d["meta"] != null && d['meta']['kind'] === 'I') {
          return I18n.t("layouts.search.budget_line_item_income");
        } else {
          return I18n.t("layouts.search.budget_line_item_expense");
        }
      case 'GobiertoCitizensCharters::Charter':
        return I18n.t("layouts.search.charter");
      case 'GobiertoCitizensCharters::Commitment':
        return I18n.t("layouts.search.charter_commitment");
      case 'GobiertoPlans::Node':
        return I18n.t("layouts.search.plan_project_item");
      case 'GobiertoData::Dataset':
        return I18n.t("layouts.search.dataset_item");
    }
  }

  function formattedResult(d){
    return `<a class="result" href="${d['resource_path']}" data-turbolinks="false">
             <h2>${d['title']}</h2>
             <div class="description">
               <div>${itemDescription(d)}</div>
               <span class="soft item_type">${itemType(d)}</span>
               ${itemUpdatedAt(d) ? ` · <span class="soft updated_at">${itemUpdatedAt(d)}</span>` : ''}
             </div>
           </a>`
  }

  var searchOptions = {
    serviceUrl: '/api/v1/search',
    dataType: 'json',
    params: window.searchClient === undefined ?
      {} :
      {
        filters:
          {
            searchable_type: window.searchClient.searchable_types
          }
      },
    beforeRender(container) {
      container.css({ width: '100%' })
    },
    transformResult: function(response) {
      return {
        suggestions: response.data.map(item => ({
          value: item.attributes.title,
          data: item.attributes
        }))
      }
    },
    formatResult: function(suggestion){
      return formattedResult(suggestion.data)
    },
    noSuggestionNotice: `<div class="result"><p>${ I18n.t("layouts.search.no_results") }</p></div>`
  };

  $input.devbridgeAutocomplete($.extend({ appendTo: $input.parent() }, AUTOCOMPLETE_DEFAULTS, searchOptions));
  $mobile_input.devbridgeAutocomplete($.extend({ appendTo: $mobile_input.parent() }, AUTOCOMPLETE_DEFAULTS, searchOptions));
});
