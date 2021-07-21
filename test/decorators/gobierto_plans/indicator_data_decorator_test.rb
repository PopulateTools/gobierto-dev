# frozen_string_literal: true

require "test_helper"

module GobiertoPlans
  class PlanDataDecoratorTest < ActiveSupport::TestCase

    def test_export_plan_to_csv_without_indicators
      plan = gobierto_plans_plans(:strategic_plan) # plan_categories_vocabulary [people_and_families_plan_term welfare_payments_plan_term center_scholarships_plan_term center_basic_needs_plan_term economy_plan_term city_plan_term]
      assert_equal "Node.Title,Node.external_id,custom_field\n", IndicatorDataDecorator.new(plan).csv
    end

    def test_export_plan_to_csv_with_single_indicator
      plan = gobierto_plans_plans(:dashboards_plan)
      expected = [
          "Node.Title,Node.external_id,custom_field,col_1,col_2,col_3,col_4",
          "Dashboards plan,4,project-metrics,Decretos Emitidos,28,55,2018-07-30",
          "Dashboards plan,4,project-metrics,decretos emitidos,13,95,2017-08-10",
          "Dashboards plan,4,project-metrics,decretos   emitidos,37,74,2016-08-04",
          "Dashboards plan,4,project-metrics,Notificaciones enviadas,32,98,2015-05-08",
          "Dashboards plan,4,project-metrics,Expedientes cerrados,48,57,2019-12-07",
          "Dashboards plan,5,project-metrics,Expedientes cerrados,10,20,2020-01-01",
          "Dashboards plan,5,project-metrics,Camas UCI,15,20,2019-08-10",
          "Dashboards plan,5,project-metrics,Expedientes cerrados,50,40,2018-08-04",
          "Dashboards plan,5,project-metrics,camas uci,356,270,2021-12-31",
          ""
        ]
      assert_equal expected.join("\n"), IndicatorDataDecorator.new(plan).csv
    end

    def test_export_plan_to_csv_with_multiples_indicator_and_different_length_of_columns
      plan = gobierto_plans_plans(:multiple_indicators_plan)
      expected = [
        "Node.Title,Node.external_id,custom_field,col_1,col_2,col_3,col_4,col_5,col_6,col_7",
        "Indicator example plan,6,multiple-indicators-statistical,1,95,10,5,3,20,2019-01-01",
        "Indicator example plan,6,multiple-indicators-statistical,3,90,5,2,2,20,2020-01-01",
        "Indicator example plan,6,multiple-indicators-statistical,4,99,3,1,0,20,2021-01-01",
        "Indicator example plan,7,multiple-indicators-opinion,60,40,2019-01-01,,,,",
        "Indicator example plan,7,multiple-indicators-opinion,50,50,2020-01-01,,,,",
        "Indicator example plan,7,multiple-indicators-opinion,30,70,2021-01-01,,,,",
        ""
      ]
      assert_equal expected.join("\n"), IndicatorDataDecorator.new(plan).csv
    end

  end
end
