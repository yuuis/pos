# frozen_string_literal: true

class DeviseTokenAuthCreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      ## Required
      t.string :provider, null: false, default: 'email'
      t.string :uid, null: false, default: ''

      ## Database authenticatable
      t.string :encrypted_password, null: false, default: ''

      ## User Info
      t.string :name
      t.string :email, null: false
      t.integer :authority_id, null: false
      t.boolean :deleted, null: false, default: false

      ## Tokens
      t.text :tokens
      t.timestamps
    end
  end
end
