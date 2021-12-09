require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    @customer_success.reject! { |cs| @away_customer_success.include? cs[:id] }
    @customer_success.sort_by! { |cs| cs[:score] }
    @customers.sort_by! { |customer| customer[:score] }

    quantity_customers_per_cs = []

    cs_index = 0
    customer_index = 0
    count = 0

    while customer_index < @customers.size && cs_index < @customer_success.size
      if @customers[customer_index][:score] <= @customer_success[cs_index][:score]
        count += 1
        customer_index += 1
        quantity_customers_per_cs[cs_index] = {id: @customer_success[cs_index][:id], customers: count }
      else
        quantity_customers_per_cs[cs_index] = {id: @customer_success[cs_index][:id], customers: count }
        cs_index += 1
        count = 0
      end
    end

    return 0 if quantity_customers_per_cs.max_by{ |k| k[:customers] }[:customers] == 0 || hasEquals?(quantity_customers_per_cs)

    quantity_customers_per_cs.max_by{ |k| k[:customers] }[:id]
  end

  def hasEquals?(quantity_customers_per_cs)
    list = []

    quantity_customers_per_cs.each do |cs|
      list << cs[:customers] if cs[:customers] != 0
    end

    list != list.uniq
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_customers_bigger_than_all_cs
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10, 100, 120]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
