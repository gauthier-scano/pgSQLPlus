# pgSQLPlus

pgSQLPlus is a PostgreSQL extension adding several features like **user rights, data mask, data deletion, data logging and static columns and variable columns**.

pgSQPlus is also an **online web application** which allows you to create/share/develop/draw your PostgreSQL database. **Collaborative way** will be soon added to the app to efficiently create database with friends or colleagues.

Official Website : [https://www.pgsqlplus.org](https://www.pgsqlplus.org/)

Official Application : [https://www.pgsqlplus.org/app.html](https://www.pgsqlplus.org/app.html)

Official Documentation : [https://www.pgsqlplus.org/documentation.html](https://www.pgsqlplus.org/documentation.html)


Currently (2020), documentation is available in **French**.
Application is available in **French and English**.

Translators are welcome. Please contact me if you got some time !

## Extension Installation

First, download the project and open the file `deploy.sh` to replace the paths depending to the PostgreSQL location and version on your computer.

Run `bash deploy.sh` to create the extension file using the most recent source. Files are generated in `ext` directory. These generated files will be automatically copied to the appropriate folder in PostgreSQL extension directory (like `[PathToPostgreSQLDir]/[version]/share/extension/`).

Create a database and a schema, using `psql` for example. This schema will be used to store the extension :

```sql
CREATE DATABASE test;
CREATE SCHEMA "extension";
```

Once created, deploy the extension in your database using `CREATE EXTENSION` and specifying the previously dedicated schema created :

```sql
CREATE EXTENSION pgsqlplus SCHEMA "extension" VERSION "1.0";
```

Extension is now ready to be used !

## Tests

To run the tests, run `bash deploy.sh -t`. This will create a database named `pgsqlplus` to process tests and **delete the previous one if it already exists**.

To process the tests, please ensure that an existing role named `postgres` with password `postgres` exists.

## Features and roadmap

Features of the extension and the application are described here : [https://www.pgsqlplus.org/documentation.html](https://www.pgsqlplus.org/documentation.html)

Ideas and futur features are available here [https://www.pgsqlplus.org/documentation.html#historique-etat-de-developpement](https://www.pgsqlplus.org/documentation.html#historique-etat-de-developpement)

## Contributing
Pull requests are welcome for the extension. For major changes, please open an issue first to discuss what you would like to change.

Extension code is available in this repository, but application code is not yet publicly available.

Please used **Application** tag for all issues related to the application and the **Extension** tag for all extension issues.

## Support

If you want to support my projects and works, do not hesitate to buy me a coffee at
[https://www.buymeacoffee.com/GauthierScano](https://www.buymeacoffee.com/GauthierScano)

Thank you !

## License
[MIT](https://choosealicense.com/licenses/mit/)
