require "test_helper"

class MerchOrderTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @epub = Epub.create!(title: "Test Book", authors: "Test Author", lang: "en")
    @document = Document.create!(userid: @user.id, epubid: @epub.id)
    @highlight = Highlight.create!(
      userid: @user.id,
      docid: @document.id,
      quote: "This is a test quote that is at least twenty characters long.",
      cfi: "epubcfi(/6/4)",
      fromauthors: "Test Author",
      fromtitle: "Test Book"
    )
    
    @merch_order = MerchOrder.new(
      user: @user,
      highlight: @highlight,
      quantity: 1,
      color: "red"
    )
  end

  test "should be valid" do
    assert @merch_order.valid?
  end

  test "belongs to user should work" do
    @merch_order.save!
    assert_equal @user, @merch_order.user
  end

  test "belongs to highlight should work" do
    @merch_order.save!
    assert_equal @highlight, @merch_order.highlight
  end

  test "quantity should be present" do
    @merch_order.quantity = nil
    assert_not @merch_order.valid?
  end

  test "quantity should be an integer" do
    @merch_order.quantity = 1.5
    assert_not @merch_order.valid?
  end

  test "quantity should be greater than 0" do
    @merch_order.quantity = 0
    assert_not @merch_order.valid?
    
    @merch_order.quantity = -1
    assert_not @merch_order.valid?
    
    @merch_order.quantity = 1
    assert @merch_order.valid?
  end

  test "color should be present" do
    @merch_order.color = ""
    assert_not @merch_order.valid?
    
    @merch_order.color = nil
    assert_not @merch_order.valid?
  end

  test "should accept valid colors" do
    valid_colors = %w[red blue green yellow black white]
    valid_colors.each do |color|
      @merch_order.color = color
      assert @merch_order.valid?, "#{color} should be valid"
    end
  end

  test "should save with valid attributes" do
    assert @merch_order.save
  end

  test "should handle different quantities" do
    (1..10).each do |quantity|
      @merch_order.quantity = quantity
      assert @merch_order.valid?, "Quantity #{quantity} should be valid"
    end
  end

  test "should require user association" do
    merch_order = MerchOrder.new(
      highlight: @highlight,
      quantity: 1,
      color: "red"
    )
    assert_not merch_order.valid?
  end

  test "should require highlight association" do
    merch_order = MerchOrder.new(
      user: @user,
      quantity: 1,
      color: "red"
    )
    assert_not merch_order.valid?
  end

  test "should create order with custom values" do
    merch_order = MerchOrder.create!(
      user: @user,
      highlight: @highlight,
      quantity: 5,
      color: "blue"
    )
    
    assert_equal 5, merch_order.quantity
    assert_equal "blue", merch_order.color
    assert_equal @user, merch_order.user
    assert_equal @highlight, merch_order.highlight
  end
end
