library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
USE ieee.math_real.ALL;
 use ieee.std_logic_arith.all;

	ENTITY BLOC IS
		port(
			CLOCK_50 : in std_logic;
			rst_n : in std_logic;			
		   REG1 : in std_logic_vector(8 downto 0);
		   --REG2 : in std_logic_vector(8 downto 0);
		   --REG3 : in std_logic_vector(8 downto 0);
		   REG_out : out std_logic_vector(7 downto 0);
			
			
			CL : out std_logic;
			SDA : inout std_logic := 'Z'
			);
			
	END ENTITY;
	
	
	ARCHITECTURE RTL OF BLOC IS
	
                
	
	constant INPUT_CLK_KHZ 			: integer := 50;
	constant INPUT_CLK_MULTIPLIER : integer := 1000;
	constant BUS_CLK_MHZ 			: integer := 400;
	constant BUS_CLK_MULTIPLIER 	: integer := 1;
	constant DATA_WITH	: integer := 8;
	
									--latch in command
	signal i2c_m_ena			: std_logic:= '0';
									--address of target slave
	signal i2c_m_addr_wr		: std_logic_vector(7 downto 0):= (others=> '0'); 
									--'0' is write, '1' is read
	signal i2c_m_rw			: std_logic:= '1';
									--data to write to slave
	signal i2c_m_data_wr		: std_logic_vector(7 downto 0):= (others=> '0'); 
									--ready send the register
	signal i2c_m_reg_rdy				: std_logic :='0';				  
									--ready send value of the register
	signal i2c_m_val_rdy				: std_logic :='0';				  
									--indicates transaction in progress
	signal i2c_m_busy			: std_logic :='0';              
									--data read from slave
	signal i2c_m_data_rd		: std_logic_vector(7 downto 0):= (others => '0');
									--flag if improper acknowledge from slave	
	signal ack_error			: std_logic:= '0';    
			 
	-- I2C SLAVE RX
	
	constant WR 			: std_logic:='0';
								-- 11h (22h) device address
	constant DEVICE	: std_logic_vector(6 downto 0):= "1110000";		
								-- 00h sub address   
	constant ADDR		: std_logic_vector(7 downto 0):= "00000000";	
	constant REGCONF : std_logic_vector(7 downto 0):= "01010001";	-- mesure en centimètres 
	constant REGRD : std_logic_vector(7 downto 0):= "00000010";	
	signal VALRD : std_logic_vector(7 downto 0);	
	
	signal i2c_s_rx_data			: std_logic_vector(7 downto 0);
	signal i2c_s_rx_data_rdy	: std_logic;								
	
	-- Build an enumerated type for the state machine
type state_type is (s0, s1, s2, s3, s4, s5, s6);

	-- Register to hold the current state
	signal state : state_type;
		 
	signal data_error: boolean := false;
	
	component I2C_M is
		generic (
										--input clock speed from user logic in KHz
			 input_clk				: integer := INPUT_CLK_KHZ;		
										--speed the I2C_M bus (scl) will run at in MHz 
			 bus_clk					: integer := BUS_CLK_MHZ;		   
										--input clock speed from user logic in KHz
			 input_clk_multiplier: integer := INPUT_CLK_MULTIPLIER;			
			 bus_clk_multiplier	: integer := BUS_CLK_MULTIPLIER
		);
		 port(
			 clk       : in     std_logic;                    --system clock
			 reset_n   : in     std_logic;                    --active low reset
			 ena       : in     std_logic;                    --latch in command
			 addr      : in     std_logic_vector(7 downto 0); --address of target slave
			 rw        : in     std_logic;                    --'0' is write, '1' is read
			 data_wr   : in     std_logic_vector(7 downto 0); --data to write to slave
			 reg_rdy	  : out	  std_logic :='0';				  --ready send the register
			 val_rdy	  : out	  std_logic :='0';				  --ready send value of the register
			 busy      : out    std_logic :='0';              --indicates transaction in progress
			 data_rd   : out    std_logic_vector(7 downto 0); --data read from slave
			 ack_error : out 	  std_logic;                    --flag if improper acknowledge from slave
			 --sda       : inout  std_logic;                    --serial data output of I2C_M bus
			 sda       : inout  std_logic;                    --serial data output of I2C_M bus
			 --scl       : inout  std_logic  --serial clock output of I2C_M bus
			 scl       : out  std_logic  --serial clock output of I2C_M bus
		);                   
	end component;
	
	BEGIN 
	
	
	UUT : I2C_M 	
	port map (	 			 
		clk 			=> CLOCK_50,
		reset_n 		=> rst_n,
		ena 			=> i2c_m_ena,
		addr 			=> i2c_m_addr_wr,
		rw 			=> i2c_m_rw,
		data_wr 		=> i2c_m_data_wr,
		reg_rdy 		=> i2c_m_reg_rdy,
		val_rdy 		=> i2c_m_val_rdy,
		busy 			=> i2c_m_busy,
		data_rd 		=> i2c_m_data_rd,
		ack_error 	=> ack_error,
		sda 			=> SDA,
		scl 			=> CL
	); 
	
	REG_out <= VALRD;
	
	P_i2c_m_write : process(rst_n,CLOCK_50)	
	variable data_wr: natural range 0 to 2**DATA_WITH-1;
	begin
		if rst_n = '0' then
			data_error <= false;
			data_wr := 0;
			i2c_m_addr_wr	<= (others => '1');
			i2c_m_data_wr <= (others => '1'); 
			i2c_m_ena <= '0';   
			i2c_m_rw <= '0'; 
			VALRD <=  ( others => '0' );
		elsif rising_edge(CLOCK_50)then
			case state is
				when s0 => 											-- Adresse du device (Sequence d'écriture)
					if i2c_m_busy = '0' then    
						state <= s1;           			
						i2c_m_addr_wr <= DEVICE & '0';		-- 0 correspond à une écriture
						i2c_m_rw <= '0';
						--data to be written
						i2c_m_data_wr <= ADDR;					-- écriture de l'adresse (0x00)
					end if;
				when s1 =>   
					i2c_m_ena <= '1';   
					if i2c_m_reg_rdy = '1' then 
						state <= s2; 
						i2c_m_data_wr <= REGCONF;				-- 0x51 = commande du capteur qui dit qu'on va écrire en cm
					end if;
				when s2 => 
					if i2c_m_val_rdy = '1' then  
						i2c_m_ena <= '1';   
						state <= s3;      
					end if;
				when s3 => 
					if i2c_m_val_rdy = '0' then 
						i2c_m_ena <= '0';   
						state <= s4;       
					end if; 
				when s4 => 
					if i2c_m_busy = '0' then    
						state <= s5;           			
						i2c_m_addr_wr <= DEVICE & '0';
					   i2c_m_rw <= '0';	
						--data to be written
						i2c_m_data_wr <= REGRD; --0x02 registre haut
					end if;
				when s5 => 
					i2c_m_ena <= '1';
					if i2c_m_reg_rdy = '1' then     
						state <= s6;           			
						i2c_m_addr_wr <= DEVICE & '1';
					   i2c_m_rw <= '1';	
						--data to be written
					end if;
				when s6 =>   
					i2c_m_ena <= '1';   
					--if i2c_m_reg_rdy = '1' then 
					if i2c_m_val_rdy = '1' then 
						state <= s4; 
						VALRD <=i2c_m_data_rd;
						i2c_m_ena <= '0';	
					end if;
				when OTHERS =>  
					state <= s0; 
			end case; 
		end if;
	end process;
	END ARCHITECTURE RTL;