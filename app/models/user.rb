class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]
  before_save :downcase_email

  has_attached_file :avatar, styles: { avatar: "80x80>", post: "50x50>", small: "40x40>" }

  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

=begin
  usuario puede enviar muchas solicitudes (relacion n:m ) ocupo tabla Frienships como pivote
  especifico la llave foranea friender_id para mi usuario 1
=end

  has_many :active_friendships,  class_name:  "Friendship",
                                 foreign_key: "friender_id",
                                 dependent: :destroy
=begin
 usuario puede recibir muchas solicitudes (relacion n:m ) ocupo tabla Frienships como pivote igual que arriba la
 llave foranea del friended_id para mi usuario 2 usando la misma tabla, en este caso un modelo Friendship puede
 pertenecer a dos usuarios distintos usando el mismo modelo User pero especificando en las llaves foraneas
 friender_id y friended_id los usuarios diferentes
=end

  has_many :passive_friendships, class_name:  "Friendship",
                                 foreign_key: "friended_id",
                                 dependent: :destroy

  # solicitudes de amistad realizadas por mi  friender -> friended
  has_many :active_friends,  through: :active_friendships,  source: :friended
  # solicitudes de amistad hacia mi  friended -> friender
  has_many :passive_friends, through: :passive_friendships, source: :friender

  has_many :posts,           dependent: :destroy # si borro un usuario tambien post
  has_many :likes,           dependent: :destroy
  has_many :comments,        dependent: :destroy

  validates :first_name, presence: true
  validates :last_name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }

  # metodo de clase User.from_omniauth para acceder
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create! do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.avatar = auth.info.picture
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  # metodo de instancia a.name para usar
  def name
    "#{first_name} #{last_name}"
  end

  # metodo de instancia busca los posts mios y de mis amigos
  def timeline
    Post.where("user_id IN (?) OR user_id = ?", friend_ids, id)
  end

  # retorna los amigos activos (solicitudes de amistad realizadas por mi) y pasivos (solicitudes de amistad hacia mi )
  def friends
    active_friends.where("accepted = ?", true) + passive_friends.where("accepted = ?", true)
  end

  def friend(recipient)
    active_friendships.create(friended_id: recipient.id)
  end

  def unfriend(friend)
    if active = active_friendships.find_by(friended_id: friend.id)
      active.destroy
    elsif passive = passive_friendships.find_by(friender_id: friend.id)
      passive.destroy
    end
  end

  # obtiene el amigo ya sea el usuario al que yo envie una solicitud (friended_id) o
  # el usuario que me envió una solicitud (friender_id)
  def get_friendship(friend)
    if active = active_friendships.find_by(friended_id: friend.id)
      active
    elsif passive = passive_friendships.find_by(friender_id: friend.id)
      passive
    end
  end

  def accept_friendship(requester)
    passive_friendships.find_by(friender_id: requester.id).accept
  end

  # metodo con ? retorna un booleano
  def friends?(user)
    friends.include?(user)
  end

  # si hay una solicitud hacia mi de un user que no he aceptado (friended -> friender)
  def pending_friend(friend)
    passive_friendships.where(["accepted = ? and friender_id = ?", false, friend.id]).first
  end

  # obtiene todas solicitudes de amistad que no he aceptado (false)
  def friend_requests
    passive_friendships.where("accepted = ?", false)
  end

  # permite loguearse al sistema sin confirmar email (pruebas)
  # metodos protected puede ser llamado desde dentro de un metodo de la misma clase o una instancia de una clase hija
  protected
  def confirmation_required?
    false
  end

  # metodos private solo se pueden ser ocupados por metodos dentro de la misma clase
  private
  def downcase_email
    self.email = email.downcase
  end

  # itera sobre la coleccion de friends (metodo arriba) contruyendo un arreglo con los id de cada registro
  def friend_ids
    friends.map(&:id)
  end
end
