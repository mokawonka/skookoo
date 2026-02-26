require "test_helper"

class ExpressionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @expression = Expression.new(
      userid: @user.id,
      cfi: "epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/3:10)",
      content: "This is an expression content."
    )
  end

  test "should be valid" do
    assert @expression.valid?
  end

  test "userid should be present" do
    @expression.userid = nil
    assert_not @expression.valid?
  end

  test "cfi should be present" do
    @expression.cfi = ""
    assert_not @expression.valid?
  end

  test "content should be present" do
    @expression.content = ""
    assert_not @expression.valid?
  end

  test "content should have minimum length of 1" do
    @expression.content = ""
    assert_not @expression.valid?
    
    @expression.content = "a"
    assert @expression.valid?
  end

  test "should save with valid attributes" do
    assert @expression.save
  end

  test "should handle long content" do
    long_content = "a" * 10000
    @expression.content = long_content
    assert @expression.valid?
    @expression.save!
    @expression.reload
    assert_equal long_content, @expression.content
  end

  test "should handle complex CFI" do
    complex_cfi = "epubcfi(/6/4[chap01ref]!/4[body01]/10[para05]/2/1:3)"
    @expression.cfi = complex_cfi
    assert @expression.valid?
    @expression.save!
    @expression.reload
    assert_equal complex_cfi, @expression.cfi
  end
end
