import Lake
open Lake DSL

package viper {
  -- add package configuration options here
}

lean_lib Viper {
  -- add library configuration options here
}

@[defaultTarget]
lean_exe viper {
  root := `Main
}
