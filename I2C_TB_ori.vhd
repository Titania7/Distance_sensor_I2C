library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE ieee.math_real.ALL;
entity I2C_TB is
end I2C_TB;

architecture behavior of I2C_TB is
component I2C is
  generic(
    input_clk : integer := 50;			--input clock speed from user logic in KHz
    bus_clk   : integer := 400;		   --speed the i2c bus (scl) will run at in MHz
	 input_clk_multiplier : integer := 1_000_000;			--input clock speed from user logic in KHz
    bus_clk_multiplier   : integer := 1_000);
  port(
    clk       : in     std_logic;                    --system clock
    reset_n   : in     std_logic;                    --active low reset
    ena       : in     std_logic;                    --latch in command
    addr      : in     std_logic_vector(7 downto 0); --address of target slave
    rw        : in     std_logic;                    --'0' is write, '1' is read
    data_wr   : in     std_logic_vector(7 downto 0); --data to write to slave
	 reg_rd	  : out	  std_logic :='0';				  --ready send the register
	 val_rd	  : out	  std_logic :='0';				  --ready send value of the register
    busy      : out    std_logic :='0';              --indicates transaction in progress
    data_rd   : out    std_logic_vector(7 downto 0); --data read from slave
    ack_error : out std_logic;                    --flag if improper acknowledge from slave
    sda       : inout  std_logic;                    --serial data output of i2c bus
    scl       : inout  std_logic);                   --serial clock output of i2c bus
end component;
signal clock,n_reset,enable,read_write,read_write2,valtemp : std_logic := '0';
signal acknow_error,ready_register,ready_value,is_busy, serial_clock : std_logic;
signal acknow_error2,ready_register2,ready_value2,is_busy2, serial_clock2 : std_logic;
signal serial_data,serial_data2 : std_logic := 'Z';
signal adresse,data_write,data_read : std_logic_vector (7 downto 0) := (others => '0');
signal adresse2,data_write2,data_read2 : std_logic_vector (7 downto 0) := (others => '0');
signal donneerecu,donneerecu2 : std_logic_vector (7 downto 0) := (others => '0');
signal donneelu,donneelucomplete,donneelu2,donneelucomplete2 : std_logic_vector (7 downto 0) := (others => '0');
signal errordonnee,errordonnee_ecriture,errordonnee_lecture,passage : boolean := false;
constant clk_period : time := 10 ns;
constant clock_entree : integer := 50;
constant bus_entree : integer := 400;
constant clock_entree_multiplier : integer := 100;
constant bus_entree_multiplier : integer := 1;
constant divider  :  integer := (clock_entree*clock_entree_multiplier/bus_entree*bus_entree_multiplier)/4;

begin
	uut : I2C 	generic map (clock_entree,bus_entree,clock_entree_multiplier,bus_entree_multiplier) 
					port map (	clock,
									n_reset,
									enable,
									adresse,
									read_write,
									data_write,
									ready_register,
									ready_value,
									is_busy,
									data_read,
									acknow_error,
									serial_data,
									serial_clock
					);
	
	uut2 : I2C 	generic map (clock_entree,bus_entree,clock_entree_multiplier,bus_entree_multiplier) 
					port map (	clock,
									n_reset,
									enable,
									adresse2,
									read_write2,
									data_write2,
									ready_register2,
									ready_value2,
									is_busy2,
									data_read2,
									acknow_error2,
									serial_data2,
									serial_clock2
					);

	read_write <= '0';
	read_write2 <= '1';
	adresse2 <= "11100111";						
	adresse <= "01100110";			
	CLK_GEN :process -- process qui va générer l'horloge séparément du reste
	begin
		clock <= '1';
			wait for clk_period/2;
		clock <= '0';
			wait for clk_period/2;
	end process;
	
	sig_reset_in : process
	begin	
		n_reset <= '0';	
		wait for clk_period*2;
		n_reset <= '1';			
		wait;
	end process;
	
	sig_busy_in : process
	begin
		enable <= '0';
		wait for clk_period*4;
		enable <= '1';
		wait until is_busy = '0';
			enable <= '0';
	end process;
	
	-- test de l'écriture des données
	sig_write_data : process
	begin
		for i in  0 to 7 loop
			data_write <= std_logic_vector(to_unsigned(2**i, data_write'length));
			donneelu <= "00000000";
			wait until serial_clock = '0';
			serial_data <= 'Z';
			wait until ready_register = '1' or ready_value = '1';
			wait until serial_clock = 'Z';
			for j in  7 downto 0 loop
				if serial_data = 'Z' then
					donneelu(j) <= '1';
				else 
					donneelu(j) <= '0';
				end if;									
				wait until serial_clock = 'Z';
				errordonnee_ecriture <= (not (donneelu(j) = data_write(j)));		
			end loop;	
			donneelucomplete <= donneelu;				
			serial_data <= '0';				
		end loop;
		wait;
	end process;	
	
	-- test des données que l'on envoie vers le slave
	sig_data_wr_in : process
	begin
		wait until is_busy = '1';
		for i in  7 downto 0 loop
			--data_write <= "10101010";
			wait until serial_clock = 'Z';
			donneerecu(i) <= serial_data;
			if serial_data = 'Z' then
				donneerecu2(i) <= '1';
			else 
				donneerecu2(i) <= '0';
			end if;			
		end loop;	
		wait for clk_period;
			errordonnee <= (not (donneerecu2 = adresse));
		wait until serial_clock = '0';
			serial_data <= '0';
		wait until serial_clock = '0';
			serial_data <= 'Z';
		wait;
	end process;
	
	-- test de la lecture des données
	sig_read_data_clock : process
	begin
		if passage = false then
			for z in  9 downto 0 loop
				wait until serial_clock2 = 'Z';
			end loop;
			passage <= true;
			serial_data2 <= '0';
			wait until serial_clock = '0';
			serial_data2 <= 'Z';
		else
			for j in  7 downto 0 loop
				wait until serial_clock2 = '0';
				wait for	clk_period*divider;
				if (std_logic(to_unsigned(j mod 2, 1)(0)) = '1') then
					serial_data2 <= 'Z';
					else
					serial_data2 <= '0';
				end if;
			end loop;
		end if;
	end process;
	
	sig_read_data_trai : process
	begin
		wait until is_busy2 = '0';		
		wait for	clk_period*divider;
		for j in  7 downto 0 loop
			if serial_data2 = 'Z' then
				donneelu2(j) <= '1';
			else 
				donneelu2(j) <= '0';
			end if;	
			if data_read2(j) = 'Z' then
				valtemp <= '1';
			else 
				valtemp <= '0';
			end if;			
			wait until serial_clock = 'Z';
			errordonnee_lecture <= (not (donneelu2(j) = valtemp));		
		end loop;			
		donneelucomplete2 <= donneelu2;
		wait until serial_clock = 'Z';
			serial_data <= '0';
		wait until serial_clock = '0';
			serial_data <= 'Z';
		
	end process;

end behavior;