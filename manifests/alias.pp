define sudo::alias (  $type = undef,
                      $name = $title,
                      $value = undef,
                      $target = undef,
                      $order = undef
) {
  include sudo
  $err_class_name = "Sudo::Alias[${title}]"

  # verify our alias name is acceptable
  case $name {
    /^[A-Z][A-Z0-9_]*$/: { $alias_name_r = $name }
    default: {
      $err_bad_name_arr = [ $err_class_name,
                              ':',
                              "alias name is invalid - ${name}" ]
      $err_bad_name = join( $err_bad_name_arr, ' ')
      fail( $err_bad_name )
    }
  }

  # verify our target sudoers file is acceptable and make sure it exists
  case $target {
    /(?i:)^[a-z]\w*$/: { $target_r = downcase($target) }
    undef: { $target_r = $sudo::default[target] }
    default: {
      $err_bad_target_arr = [ $err_class_name,
                              ':',
                              "target is invalid - ${target}" ]
      $err_bad_target = join( $err_bad_target_arr, ' ')
      fail( $err_bad_target )
    }
  }
  if ! defined( Sudo::Target[$target_r] ) { sudo::target { $target_r: } }

  case $type {

    # process a host_alias
    'host':
      {
        # value should contain Hostnames and/or IPs
        if is_array( $value ) { $value_r = $value }
        else { $value_r = split( $value, '[,|:]' ) }


        $erb = 'Host_Alias <% alias_name_r -%> = <%= value_r.join(\', \') %>'
        $frag = "sudoers_${target_r}_host_alias_${alias_name_r}"
        $order_d = $sudo::order[host_alias]
      }

    # process a cmnd_alias
    'cmnd':
      {
        if is_array( $value ) { $value_r = $value }
        else { $value_r = split( $value, '[,|:]' ) }

        $erb = 'Cmnd_Alias <%= alias_name_r %> = <%= value_r.join(\', \') %>'
        $frag = "sudoers_${target_r}_cmnd_alias_${alias_name_r}"
        $order_d = $sudo::order[cmnd_alias]
      }

    # process a user_alias
    'user':
      {
        $erb = 'User_Alias <%= alias_name_r %> = <%= value_r.join(\', \') %>'
        $frag = "sudoers_${target}_user_alias_${alias_name_r}"
        $order_d = $sudo::order[user_alias]
      }

    # pebkac
    default:
      {
        $err_type_arr = [ $err_class_name, ':',
                          "invalid type - ${type}." ]
        $err_type = join( $err_type_arr, ' ' )
        fail( $err_type )
      }
  }

  case $order {
    /^[0-9]+$/: { $order_r = lead( $order, 2 ) }
    undef: { $order_r = lead( $order_d, 2 ) }
    default: {
      $err_bad_order_arr = [ $err_class_name, ':',
                              "order is invalid - ${order}" ]
      $err_bad_order = join( $err_bad_order_arr, ' ' )
      fail( $err_bad_order )
    }
  }

  concat::fragment { $frag:
      order   => $order_r,
      content => inline_template("${erb}\n"),
      target  => $target_r,
  }
}
