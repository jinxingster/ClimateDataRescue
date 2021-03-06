class User < ActiveRecord::Base
  has_many :transcriptions
  has_many :pages
  has_many :annotations, through: :transcriptions
  #before_filter :authorize_admin, except [:index, :show]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  #attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :admin, :avatar, :about, :contributions, :rank, :transcription_id

  #attachment for user afatar and settings
  has_attached_file :avatar,
  :styles => {
    :thumb    => ['100x100#',  :jpg, :quality => 70],
    :medium  => ['200x200#',  :jpg, :quality => 70],
    :preview  => ['480x480#',  :jpg, :quality => 70],
    :large    => ['600>',      :jpg, :quality => 70],
    :retina   => ['1200>',     :jpg, :quality => 30]
  },
  :convert_options => {
    :thumb    => '-set colorspace sRGB -strip',
    :preview  => '-set colorspace sRGB -strip',
    :large    => '-set colorspace sRGB -strip',
    :retina   => '-set colorspace sRGB -strip -sharpen 0x0.5'
  },
  default_style: :thumb,
  url: "/system/:attachment/:style/:hash.:extension",
  hash_secret: "SECRET"

  
  validates_attachment :avatar,
    :size => { :in => 0..2.megabytes },
    :content_type => { :content_type => /^image\/(jpeg|jpg|png)$/ }

  def privileged?
    self.admin?
  end
  #Function called when user creates a new transcription, increments their contribution count for display and future ranking implementation. Called from transcriptions#new
  def increment_contributions
    contributions = self.contributions.nil? ? 0 : self.contributions
    contributions += 1
    self.save
  end
end
