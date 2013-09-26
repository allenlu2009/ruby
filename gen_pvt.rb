#/usr/bin/env ruby
# gen_pvt.rb

class Pvt

def initialize()
end

pmos_core = [S, T, F];  
nmos_core = [S, T, F];
pmos_io   = [S, T, F];
nmos_io   = [S, T, F];
supply_ratio = [S, T, F] %% [0.9, 1.0, 1.1];
temp      = [S, T, F] %% [-20, 30, 125]

supply_core = 1.8;
supply_io   = 3.3;

end
