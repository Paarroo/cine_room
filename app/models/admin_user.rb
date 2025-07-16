class AdminUser < ApplicationRecord
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable,
           :recoverable, :rememberable, :validatable

    enum :status, {
       inactive: 0,
       pending: 1,
       active: 2,
       super_admin: 3
     }
end
