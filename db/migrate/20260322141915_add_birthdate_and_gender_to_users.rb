class AddBirthdateAndGenderToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :birthdate, :date
    add_column :users, :gender, :string
  end
end
