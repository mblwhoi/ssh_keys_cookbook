actions :create, :create_if_missing

attribute :user, :kind_of => String, :required => true
attribute :type, :regex => /^rsa|dsa$/, :default => "dsa"
attribute :bits, :kind_of => Integer, :default => 1024
attribute :passphrase, :kind_of => String, :default => ""
attribute :comment, :kind_of => String, :default => ""
