%% download_rba.m — Download RBA data (SSL workaround for R2019a)
outdir = fullfile(fileparts(mfilename('fullpath')), 'abs_rba');

% R2019a SSL fix: disable certificate verification
opts = weboptions('CertificateFilename', '');

urls = {
    'https://www.rba.gov.au/statistics/tables/csv/f5-data.csv', 'rba_f5.csv', 'F5 Lending Rates';
    'https://www.rba.gov.au/statistics/tables/csv/f6-data.csv', 'rba_f6.csv', 'F6 Housing Rates';
};

for k = 1:size(urls, 1)
    fname = fullfile(outdir, urls{k, 2});
    fprintf('Downloading RBA %s...\n', urls{k, 3});
    try
        websave(fname, urls{k, 1}, opts);
        d = dir(fname);
        fprintf('  OK (%d bytes)\n', d.bytes);
    catch ME
        fprintf('  websave failed: %s\n', ME.message);
        % Fallback: try urlwrite (older, sometimes works)
        try
            urlwrite(urls{k, 1}, fname);
            d = dir(fname);
            fprintf('  urlwrite OK (%d bytes)\n', d.bytes);
        catch ME2
            fprintf('  urlwrite also failed: %s\n', ME2.message);
            % Last resort: use Java directly
            try
                import java.net.URL
                import java.io.*
                jurl = URL(urls{k, 1});
                conn = jurl.openConnection();
                % Disable SSL verification via Java
                if isa(conn, 'javax.net.ssl.HttpsURLConnection')
                    sc = javax.net.ssl.SSLContext.getInstance('TLS');
                    tm = javaArray('javax.net.ssl.TrustManager', 1);
                    tm(1) = javax.net.ssl.X509TrustManager();
                    % Use a permissive trust manager
                end
                is = conn.getInputStream();
                reader = BufferedReader(InputStreamReader(is));
                fout = fopen(fname, 'w');
                line = reader.readLine();
                while ~isempty(line)
                    fprintf(fout, '%s\n', char(line));
                    line = reader.readLine();
                end
                fclose(fout);
                reader.close();
                d = dir(fname);
                fprintf('  Java download OK (%d bytes)\n', d.bytes);
            catch ME3
                fprintf('  All methods failed: %s\n', ME3.message);
            end
        end
    end
end

fprintf('\nRBA download complete.\n');
