def initialize(*args)
  super
  @action = :create_if_missing
end

# Shared method for creating key.
def create_key(options={})

  user = new_resource.user
  uid = node[:etc][:passwd]["#{new_resource.user}"]["uid"]
  gid = node[:etc][:passwd]["#{new_resource.user}"]["gid"]
  user_dir = node[:etc][:passwd]["#{new_resource.user}"]["dir"]
  key_type = new_resource.type
  bits = new_resource.bits
  passphrase = new_resource.passphrase
  comment = new_resource.comment

  # Check bits.
  if key_type == 'rsa'
    if bits < 768
      raise "Insufficent number of bits for RSA key.  Number of bits was '#{bits}', must be at least 768.  Generally 2048 is considered sufficient."
    end
  elsif key_type =='dsa'
    # DSA keys must be 1024
    bits = 1024
  end

  private_key_file = "#{user_dir}/.ssh/id_#{key_type}"
  public_key_file = "#{private_key_file}.pub"
  key_files = [private_key_file,public_key_file]

  directory "#{user_dir}/.ssh" do
    owner user
    group gid
    mode '0700'
  end
  
  keygen_command = "ssh-keygen -q -t #{key_type} -b #{bits} -f #{private_key_file} -P \"#{passphrase}\""

  # Optionally add comment if making RSA key.
  if key_type == 'rsa' && comment
    keygen_command += " -C \"#{comment}\""
  end

  # Append commands to set permissions on keys.
  key_files.each do |kf|
    keygen_command += "; chown #{uid}:#{gid} #{kf}"
  end

  # If forcing creation of new key, remove old keys.
  if options['force']

    # Generate command to remove old keys and prepend to keygen command.
    rm_cmd = key_files.map{|kf| "rm -f #{kf}"}.join(';')

    execute "ssh-keygen #{private_key_file}" do
      command "#{rm_cmd}; #{keygen_command}"
    end    

  # Otherwise check if key already exists.
  else
    execute "ssh-keygen #{private_key_file}" do
      creates private_key_file
      command keygen_command
    end      
  end

end


action :create do
  create_key({'force' => true})
end

action :create_if_missing do
  create_key()
end

