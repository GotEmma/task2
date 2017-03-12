/* This is the driving engine of the program. It parses the command-line
 * arguments and calls the appropriate methods in the other classes.
 *
 * You should edit this file in three ways:
 * 1) Insert your database username and password in the proper places.
 * 2) Implement the generation of the world by reading the world file.
 * 3) Implement the three functions showPossibleMoves, showPlayerAssets
 *    and showScores.
 */
import java.math.BigDecimal;
import java.lang.*;
import java.net.URL;
import java.sql.*; // JDBC stuff.
import java.util.*;
import java.io.*;  // Reading user input.
import java.util.concurrent.Executor;

public class Game
{
	public class Player
	{
		String playername;
		String personnummer;
		String country;
		private String startingArea;

		public Player (String name, String nr, String cntry, String startingArea) {
			this.playername = name;
			this.personnummer = nr;
			this.country = cntry;
			this.startingArea = startingArea;
		}
	}

 	String USERNAME = "USERNAME";
 	String PASSWORD = "PASSWORD";

	/* Print command optionssetup.
	* /!\ you don't need to change this function! */
	public void optionssetup() {
		System.out.println();
		System.out.println("Setup-Options:");
		System.out.println("		n[ew player] <player name> <personnummer> <country>");
		System.out.println("		d[one]");
		System.out.println();
	}

 	/* Print command options.
 	* /!\ you don't need to change this function! */
 	public void options() {
		System.out.println("\nOptions:");
		System.out.println("    n[ext moves] [area name] [area country]");
		System.out.println("    l[ist properties] [player number] [player country]");
		System.out.println("    s[cores]");
		System.out.println("    r[efund] <area1 name> <area1 country> [area2 name] [area2 country]");
		System.out.println("    b[uy] [name] <area1 name> <area1 country> [area2 name] [area2 country]");
		System.out.println("    m[ove] <area1 name> <area1 country>");
		System.out.println("    p[layers]");
		System.out.println("    q[uit move]");
		System.out.println("    [...] is optional\n");
	}
	//extra insert to prevent duplicate code
	void insertArea(Connection conn, String name, String country, String population) throws SQLException  {
		try {
		//Check if the country alrea exists, if not insert it
		PreparedStatement checkCountryPstmt = conn.prepareStatement("SELECT * FROM Countries WHERE name = ?");
		checkCountryPstmt.setString(1, country);
		ResultSet rs = checkCountryPstmt.executeQuery();
		if(!rs.next()){
			PreparedStatement countryPstmt = conn.prepareStatement("INSERT INTO Countries VALUES (?)");
			countryPstmt.setString(1, country);
			countryPstmt.executeUpdate();
			countryPstmt.close();
		}
		checkCountryPstmt.close();
	} catch (SQLException e) {
		e.printStackTrace();
		System.out.println("something went wrong inserting country");
	}
		try {
			//insert area
			PreparedStatement areaPstmt = conn.prepareStatement("INSERT INTO Areas VALUES (?, ?, cast(? as INT))");
			areaPstmt.setString(1, country);
			areaPstmt.setString(2, name);
			areaPstmt.setString(3, population);
			areaPstmt.executeUpdate();
			areaPstmt.close();
		} catch (SQLException e) {
			e.printStackTrace();
			 System.out.println("something went wrong inserting area");
		}
	}

	/* Given a town name, country and population, this function
 	 * should try to insert an area and a town (and possibly also a country)
 	 * for the given attributes.
 	 */
	void insertTown(Connection conn, String name, String country, String population) throws SQLException  {
		insertArea(conn, name, country, population);
		try {
			//insert town
			PreparedStatement townPstmt = conn.prepareStatement("INSERT INTO Towns VALUES (?, ?)");
			townPstmt.setString(1, country);
			townPstmt.setString(2, name);
			townPstmt.executeUpdate();
			townPstmt.close();

		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong inserting town");
		}
	}

	/* Given a city name, country and population, this function
 	 * should try to insert an area and a city (and possibly also a country)
 	 * for the given attributes.
 	 * The city visitbonus should be set to 0.
 	 */
	void insertCity(Connection conn, String name, String country, String population) throws SQLException {
		insertArea(conn, name, country, population);
		try {
			//insert city
			PreparedStatement cityPstmt = conn.prepareStatement("INSERT INTO Cities VALUES (?, ?, 0)");
			cityPstmt.setString(1, country);
			cityPstmt.setString(2, name);
			cityPstmt.executeUpdate();
			cityPstmt.close();

		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong inserting city");
		}
	}

	/* Given two areas, this function
 	 * should try to insert a government owned road with tax 0
 	 * between these two areas.
 	 */
	void insertRoad(Connection conn, String area1, String country1, String area2, String country2) throws SQLException {
		try {
			PreparedStatement roadPstmt = conn.prepareStatement("INSERT INTO Roads VALUES (?, ?, ?, ?, ?, ?, cast (? as NUMERIC) )");
			roadPstmt.setString(1, country1);
			roadPstmt.setString(2, area1);
			roadPstmt.setString(3, country2);
			roadPstmt.setString(4, area2);
			roadPstmt.setString(5, "");
			roadPstmt.setString(6, "");
			roadPstmt.setString(7, "0");
			roadPstmt.executeUpdate();
			roadPstmt.close();

		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong inserting road");
		}
	}

	/* Given a player, this function
	 * should return the area name of the player's current location.
	 */
	String getCurrentArea(Connection conn, Player person) throws SQLException {
		String location;
		try {
			PreparedStatement st = conn.prepareStatement("SELECT locationarea FROM Persons WHERE personnummer = ? AND country = ? ");
			st.setString(1, person.personnummer);
			st.setString(2, person.country);
			ResultSet rs = st.executeQuery();
			rs.next();
			location = rs.getString(1);
			rs.close();
			st.close();
			return location;
		}
		catch (SQLException e){
			e.printStackTrace();
			System.out.println("something went wrong getting current Area");
			return null;
		}
	}

	/* Given a player, this function
	 * should return the country name of the player's current location.
	 */
	String getCurrentCountry(Connection conn, Player person) throws SQLException {
		String location;
		try {
			PreparedStatement st = conn.prepareStatement("SELECT locationcountry FROM Persons WHERE personnummer = ? AND country = ? ");
			st.setString(1, person.personnummer);
			st.setString(2, person.country);
			ResultSet rs = st.executeQuery();
			rs.next();
			location = rs.getString(1);
			rs.close();
			st.close();
			return location;
		}
		catch (SQLException e){
			e.printStackTrace();
			System.out.println("something went wrong getting current country");
			return null;
		}
	}

	/* Given a player, this function
 	 * should try to insert a table entry in persons for this player
	 * and return 1 in case of a success and 0 otherwise.
 	 * The location should be random and the budget should be 1000.
	 */
	int createPlayer(Connection conn, Player person) throws SQLException {
		String randArea = "";
		String randCountry = "";
		int rand;
		int total = 0;
		int returnValue;

		try {
			Statement count = conn.createStatement();
			ResultSet rs = count.executeQuery("SELECT * FROM Areas");
			while (rs.next()) {
				total ++;
			}
			rs.close();
			// Start at line 2, not counting "" as an area
			rand = 2 + (int) (Math.random() * (total - 1));

			count.close();

			Statement find = conn.createStatement();
			ResultSet rsf = find.executeQuery("SELECT * FROM Areas");
			while (rsf.next()) {
				if (rsf.getRow() == rand) {
					randArea = rsf.getString(2);
					randCountry = rsf.getString(1);
					break;
				}
			}
			find.close();
			rsf.close();

			PreparedStatement st = conn.prepareStatement("INSERT INTO Persons VALUES (?,?,?,?,?, cast(? as NUMERIC))");
			st.setString(1, person.country);
			st.setString(2, person.personnummer);
			st.setString(3, person.playername);
			st.setString(4, randCountry);
			st.setString(5, randArea);
			st.setString(6, "1000");
			returnValue = st.executeUpdate();
			st.close();
			return returnValue;
		}
		catch (SQLException e){
			e.printStackTrace();
			System.out.println("something went wrong creating person");
			return 0;
		}
	}

	/* Given a player and an area name and country name, this function
	 * sould show all directly-reachable destinations for the player from the
	 * area from the arguments.
	 * The output should include area names, country names and the associated road-taxes
 	 */
	void getNextMoves(Connection conn, Player person, String area, String country) throws SQLException {
		try {
			PreparedStatement movesPstmt = conn.prepareStatement("SELECT destcounry, destarea, cost FROM NextMoves WHERE personcountry = ? AND personnummer = ? AND country = ? AND area = ?");
			movesPstmt.setString(1, person.country);
			movesPstmt.setString(2, person.personnummer);
			movesPstmt.setString(3, country);
			movesPstmt.setString(4, area);
			ResultSet rs = movesPstmt.executeQuery();
				while (rs.next()){
					System.out.println("Destination: ");
					System.out.println(rs.getString(2) + ", " + rs.getString(1));
					System.out.println("Cost:");
					System.out.println(rs.getString(3));
				}
				rs.close();


		} catch (SQLException e) {
			System.out.println("something went wrong getting next moves");
	}
 	}

	/* Given a player, this function
  	 * sould show all directly-reachable destinations for the player from
	 * the player's current location.
	 * The output should include area names, country names and the associated road-taxes
	 */
	void getNextMoves(Connection conn, Player person) throws SQLException {
		getNextMoves(conn, person, getCurrentArea(conn, person), getCurrentCountry(conn, person));
	}

	/* Given a personnummer and a country, this function
	 * should list all properties (roads and hotels) of the person
	 * that is identified by the tuple of personnummer and country.
	 */
	void listProperties(Connection conn, String personnummer, String country) {
		try {
			PreparedStatement roadPstmt = conn.prepareStatement("SELECT fromcountry, fromarea, tocountry, toarea, roadtax FROM Roads WHERE ownercountry = ? AND ownerpersonnummer = ?");
			roadPstmt.setString(1, country);
			roadPstmt.setString(2, personnummer);
			ResultSet rs = roadPstmt.executeQuery();
				while (rs.next()){
					System.out.println("Road:");
					System.out.println("From:\n" + rs.getString(1) + ", ");
					System.out.println(rs.getString(2));
					System.out.println("To:\n" + rs.getString(3) + ", ");
					System.out.println(rs.getString(4));
					System.out.println("Roadtax:\n" + rs.getString(5));
				}
				rs.close();
				} catch (SQLException e) {
					System.out.println("something went wrong listing (road) properties");
			}
			try {
				PreparedStatement hotelPstmt = conn.prepareStatement("SELECT name, locationcountry, locationname FROM Hotels WHERE ownercountry = ? AND ownerpersonnummer = ?");
				hotelPstmt.setString(1, country);
				hotelPstmt.setString(2, personnummer);
				ResultSet rs = hotelPstmt.executeQuery();
				while (rs.next()){
					System.out.println("Hotel:");
					System.out.println("Name: " + rs.getString(1));
					System.out.println("In: " + rs.getString(2) + ", " + rs.getString(3));
				}
				rs.close();
				} catch (SQLException e) {
					System.out.println("something went wrong listing (hotel) properties");
				}
			}

	/* Given a player, this function
	 * should list all properties of the player.
	 */
	void listProperties(Connection conn, Player person) throws SQLException {
		listProperties(conn, person.personnummer, person.country);
	}

	/* This function should print the budget, assets and refund values for all players.
	 */
	void showScores(Connection conn) throws SQLException {
		//hur kolla alla spelare? inte samma sak som alla personer?
		try {
			PreparedStatement scorePstmt = conn.prepareStatement("SELECT * FROM AssetSummary");
			ResultSet rs = scorePstmt.executeQuery();
			while (rs.next()){
				System.out.println("Playercountry: " + rs.getString(1) + "Player personnummer: " + rs.getString(2) );
				System.out.println("Budget: " + rs.getString(3));
				System.out.println("Assets: " + rs.getString(4));
				System.out.println("Refund: " + rs.getString(5));
			}
			rs.close();
		} catch (SQLException e) {
			System.out.println("something went wrong listing scores");
		}
	}

	/* Given a player, a from area and a to area, this function
	 * should try to sell the road between these areas owned by the player
	 * and return 1 in case of a success and 0 otherwise.
	 */
	int sellRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
		//check if there is such a road or asume it is??
		int returnValue;
		try {
			PreparedStatement sellRoadPstmt = conn.prepareStatement("DELETE FROM Roads WHERE (ownercountry = ? AND ownerpersonnummer = ?) AND ((fromcountry = ? AND fromarea = ? AND tocountry = ? AND toarea = ?) OR (fromcountry = ? AND fromarea = ? AND tocountry = ? AND toarea = ?))");
			sellRoadPstmt.setString(1, person.country);
			sellRoadPstmt.setString(2, person.personnummer);
			sellRoadPstmt.setString(3, country1);
			sellRoadPstmt.setString(4, area1);
			sellRoadPstmt.setString(5, country2);
			sellRoadPstmt.setString(6, area2);
			sellRoadPstmt.setString(7, country2);
			sellRoadPstmt.setString(8, area2);
			sellRoadPstmt.setString(9, country1);
			sellRoadPstmt.setString(10, area1);
			returnValue = sellRoadPstmt.executeUpdate();
			sellRoadPstmt.close();
			return returnValue;
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong selling road");
			return 0;
		}
	}

	/* Given a player and a city, this function
	 * should try to sell the hotel in this city owned by the player
	 * and return 1 in case of a success and 0 otherwise.
	 */
	int sellHotel(Connection conn, Player person, String city, String country) throws SQLException {
		int returnValue;
		try {
			PreparedStatement sellHotelPstmt = conn.prepareStatement("DELETE FROM Hotels WHERE ownercountry = ? AND ownerpersonnummer = ? AND locationcountry = ? AND locationname = ? ");
			sellHotelPstmt.setString(1, person.country);
			sellHotelPstmt.setString(2, person.personnummer);
			sellHotelPstmt.setString(3, country);
			sellHotelPstmt.setString(4, city);
			returnValue = sellHotelPstmt.executeUpdate();
			sellHotelPstmt.close();
			return returnValue;
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong selling hotel");
			return 0;
		}
	}

	/* Given a player, a from area and a to area, this function
	 * should try to buy a road between these areas owned by the player
	 * and return 1 in case of a success and 0 otherwise.
	 */
	int buyRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
		try {
			PreparedStatement roadPstmt = conn.prepareStatement("INSERT INTO Roads VALUES (?,?,?,?,?,?,getval('roadtax'))");
			roadPstmt.setString(1, country1);
			roadPstmt.setString(2, area1);
			roadPstmt.setString(3, country2);
			roadPstmt.setString(4, area2);
			roadPstmt.setString(5, person.country);
			roadPstmt.setString(6, person.personnummer);
			roadPstmt.executeUpdate();
			roadPstmt.close();
			return 1;
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong buying road");
			return 0;
		}
	}

	/* Given a player and a city, this function
	 * should try to buy a hotel in this city owned by the player
	 * and return 1 in case of a success and 0 otherwise.
	 */
	int buyHotel(Connection conn, Player person, String name, String city, String country) throws SQLException {
		int returnValue;
		try {
			PreparedStatement hotelPstmt = conn.prepareStatement("INSERT INTO Hotels VALUES (?,?,?,?,?)");
			hotelPstmt.setString(1, name);
			hotelPstmt.setString(2, country);
			hotelPstmt.setString(3, city);
			hotelPstmt.setString(4, person.country);
			hotelPstmt.setString(5, person.personnummer);
			returnValue = hotelPstmt.executeUpdate();
			hotelPstmt.close();
			return returnValue;
		} catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong buying hotel");
			return 0;
		}
	}

	/* Given a player and a new location, this function
	 * should try to update the players location
	 * and return 1 in case of a success and 0 otherwise.
	 */
	int changeLocation(Connection conn, Player person, String area, String country) throws SQLException {
		int returnValue;
		try {
			PreparedStatement st = conn.prepareStatement("UPDATE Persons SET locationarea = ?, locationcountry = ? WHERE personnummer = ? AND country = ?");
			st.setString(1, area);
			st.setString(2, country);
			st.setString(3, person.personnummer);
			st.setString(4, person.country);
			returnValue = st.executeUpdate();
			st.close();
			return returnValue;
		}
		catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong changing location");
			return 0;
		}
	}

	/* This function should add the visitbonus of 1000 to a random city
 	 */
	void setVisitingBonus(Connection conn) throws SQLException {
		//int bonus = 1000;
		int rand;
		int total = 0;
		String name = "";
		String country = "";

		try {
			Statement st = conn.createStatement();
			ResultSet rs = st.executeQuery("SELECT * FROM Cities");
			while(rs.next()){
				total++;
			}

			rand = 1 + (int) (Math.random() * total);
			st.close();
			rs.close();

			Statement find = conn.createStatement();
			ResultSet rsf = find.executeQuery("SELECT * FROM Cities");
			while (rsf.next()) {
				if (rsf.getRow() == rand) {
					name = rsf.getString(2);
					country = rsf.getString(1);
					break;
				}
			}
			find.close();
			rsf.close();

			PreparedStatement insert = conn.prepareStatement("UPDATE Cities SET visitbonus = cast(? as INT) WHERE name = ? AND country = ? ");
			insert.setString(1, "1000");
			insert.setString(2, name);
			insert.setString(3, country);
			insert.executeUpdate();
			insert.close();
		}
		catch (SQLException e) {
			e.printStackTrace();
			System.out.println("something went wrong setting visiting bonus");
		}

	}

	/* This function should print the winner of the game based on the currently highest budget.
 	 */
	void announceWinner(Connection conn) throws SQLException {
		/*
		List<ResultSet> winner = new ArrayList<ResultSet>();
		Statement st = conn.createStatement();
		ResultSet rs = st.executeQuery("SELECT budget FROM Persons");
		while (rs.next()){
			if (rs.getInt(6) > winner.get(0).getInt(6)){
				winner.clear();
				winner.add(rs);
			}
			else if (rs.getInt(6) == winner.get(0).getInt(6)){
				winner.add(rs);
			}
		}
		for (int i = 0; winner.size()<i; i++){
			System.out.println(rs.toString());
		}*/
		Statement st = conn.createStatement();
		ResultSet rs = st.executeQuery("SELECT personnummer, country FROM Persons ORDER by budget DESC");
		rs.next();
		System.out.println("The winner is: " + rs.getString(2) + " from " + rs.getString(1));
		rs.close();
		st.close();
	}


	void play (String worldfile) throws IOException {

		// Read username and password from config.cfg
		try {
			BufferedReader nf = new BufferedReader(new FileReader("config.cfg"));
			String line;
			if ((line = nf.readLine()) != null) {
				USERNAME = line;
			}
			if ((line = nf.readLine()) != null) {
				PASSWORD = line;
			}
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}

		if (USERNAME.equals("USERNAME") || PASSWORD.equals("PASSWORD")) {
			System.out.println("CONFIG FILE HAS WRONG FORMAT");
			return;
		}

		try {
			try {
				Class.forName("org.postgresql.Driver");
			} catch (Exception e) {
				System.out.println(e.getMessage());
			}
			String url = "jdbc:postgresql://ate.ita.chalmers.se/";
			Properties props = new Properties();
			props.setProperty("user",USERNAME);
			props.setProperty("password",PASSWORD);

			final Connection conn = DriverManager.getConnection(url, props);

			/* This block creates the government entry and the necessary
			 * country and area for that.
			 */
			try {
				PreparedStatement statement = conn.prepareStatement("INSERT INTO Countries (name) VALUES (?)");
				statement.setString(1, "");
				statement.executeUpdate();
				statement = conn.prepareStatement("INSERT INTO Areas (country, name, population) VALUES (?, ?, cast(? as INT))");
				statement.setString(1, "");
				statement.setString(2, "");
				statement.setString(3, "1");
				statement.executeUpdate();
				statement = conn.prepareStatement("INSERT INTO Persons (country, personnummer, name, locationcountry, locationarea, budget) VALUES (?, ?, ?, ?, ?, cast(? as NUMERIC))");
				statement.setString(1, "");
				statement.setString(2, "");
				statement.setString(3, "Government");
				statement.setString(4, "");
				statement.setString(5, "");
				statement.setString(6, "0");
				statement.executeUpdate();
			} catch (SQLException e) {
				System.out.println(e.getMessage());
			}

			// Initialize the database from the worldfile
			try {
				BufferedReader br = new BufferedReader(new FileReader(worldfile));
				String line;
				while ((line = br.readLine()) != null) {
				String[] cmd = line.split(" +");
					if ("ROAD".equals(cmd[0]) && (cmd.length == 5)) {
						insertRoad(conn, cmd[1], cmd[2], cmd[3], cmd[4]);
					} else if ("TOWN".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a town entry in the database */
						insertTown(conn, cmd[1], cmd[2], cmd[3]);
					} else if ("CITY".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a city entry in the database */
						insertCity(conn, cmd[1], cmd[2], cmd[3]);
					}
				}
			} catch (Exception e) {
				System.out.println(e.getMessage());
			}

			ArrayList<Player> players = new ArrayList<Player>();

			while(true) {
				optionssetup();
				String mode = readLine("? > ");
				String[] cmd = mode.split(" +");
				cmd[0] = cmd[0].toLowerCase();
				if ("new player".startsWith(cmd[0]) && (cmd.length == 5)) {
					Player nextplayer = new Player(cmd[1], cmd[2], cmd[3], cmd[4]);
					if (createPlayer(conn, nextplayer) == 1) {
						players.add(nextplayer);
					}
				} else if ("done".startsWith(cmd[0]) && (cmd.length == 1)) {
					break;
				} else {
					System.out.println("\nInvalid option.");
				}
			}

			System.out.println("\nGL HF!");
			int roundcounter = 1;
			int maxrounds = 5;
			while(roundcounter <= maxrounds) {
				System.out.println("\nWe are starting the " + roundcounter + ". round!!!");
				/* for each player from the playerlist */
				for (int i = 0; i < players.size(); ++i) {
					System.out.println("\nIt's your turn " + players.get(i).playername + "!");
					System.out.println("You are currently located in " + getCurrentArea(conn, players.get(i)) + " (" + getCurrentCountry(conn, players.get(i)) + ")");
					while (true) {
						options();
						String mode = readLine("? > ");
						String[] cmd = mode.split(" +");
						cmd[0] = cmd[0].toLowerCase();
						if ("next moves".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* Show next moves from a location or current location. Turn continues. */
							if (cmd.length == 1) {
								String area = getCurrentArea(conn, players.get(i));
								String country = getCurrentCountry(conn, players.get(i));
								getNextMoves(conn, players.get(i));
							} else {
								getNextMoves(conn, players.get(i), cmd[1], cmd[2]);
							}
						} else if ("list properties".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* List properties of a player. Can be a specified player
							   or the player himself. Turn continues. */
							if (cmd.length == 1) {
								listProperties(conn, players.get(i));
							} else {
								listProperties(conn, cmd[1], cmd[2]);
							}
						} else if ("scores".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
							showScores(conn);
						} else if ("players".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
							System.out.println("\nPlayers:");
							for (int k = 0; k < players.size(); ++k) {
								System.out.println("\t" + players.get(k).playername + ": " + players.get(k).personnummer + " (" + players.get(k).country + ") ");
							}
						} else if ("refund".startsWith(cmd[0]) && (cmd.length == 3 || cmd.length == 5)) {
							if (cmd.length == 5) {
								/* Sell road from arguments. If no road was sold the turn
								   continues. Otherwise the turn ends. */
								if (sellRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
									break;
								} else {
									System.out.println("\nTry something else.");
								}
							} else {
								/* Sell hotel from arguments. If no hotel was sold the turn
								   continues. Otherwise the turn ends. */
								if (sellHotel(conn, players.get(i), cmd[1], cmd[2]) == 1) {
									break;
								} else {
									System.out.println("\nTry something else.");
								}
							}
						} else if ("buy".startsWith(cmd[0]) && (cmd.length == 4 || cmd.length == 5)) {
							if (cmd.length == 5) {
								/* Buy road from arguments. If no road was bought the turn
								   continues. Otherwise the turn ends. */
								if (buyRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
									break;
								} else {
									System.out.println("\nTry something else.");
								}
							} else {
								/* Buy hotel from arguments. If no hotel was bought the turn
								   continues. Otherwise the turn ends. */
								if (buyHotel(conn, players.get(i), cmd[1], cmd[2], cmd[3]) == 1) {
									break;
								} else {
									System.out.println("\nTry something else.");
								}
							}
						} else if ("move".startsWith(cmd[0]) && cmd.length == 3) {
							/* Change the location of the player to the area from the arguments.
							   If the move was legal the turn ends. Otherwise the turn continues. */
							if (changeLocation(conn, players.get(i), cmd[1], cmd[2]) == 1) {
								break;
							} else {
								System.out.println("\nTry something else.");
							}
						} else if ("quit".startsWith(cmd[0]) && cmd.length == 1) {
							/* End the move of the player without any action */
							break;
						} else {
							System.out.println("\nYou chose an invalid option. Try again.");
						}
					}
				}
				setVisitingBonus(conn);
				++roundcounter;
			}
			announceWinner(conn);
			System.out.println("\nGG!\n");

			conn.close();
		} catch (SQLException e) {
			System.err.println(e);
			System.exit(2);
		}
	}

	private String readLine(String s) throws IOException {
		System.out.print(s);
		BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
		char c;
		StringBuilder stringBuilder = new StringBuilder();
		do {
			c = (char) bufferedReader.read();
			stringBuilder.append(c);
		} while(String.valueOf(c).matches(".")); // Without the DOTALL switch, the dot in a java regex matches all characters except newlines

		System.out.println("");
		stringBuilder.deleteCharAt(stringBuilder.length()-1);

		return stringBuilder.toString();
	}

	/* main: parses the input commands.
 	* /!\ You don't need to change this function! */
	public static void main(String[] args) throws Exception
	{
		String worldfile = args[0];
		Game g = new Game();
		g.play(worldfile);
	}
}
